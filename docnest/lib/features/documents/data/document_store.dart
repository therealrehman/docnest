import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/database/app_database.dart';
import '../../folders/data/folder_record.dart';
import 'document_record.dart';
import 'filing_rule_record.dart';

/// Keeps imported files in the app's private folder. Document details, folders
/// and tags live in a local SQLite database (Drift).
///
/// NOT encrypted yet. File contents and names are stored in plain form on the device.
/// Encryption (AES-GCM with Android Keystore) arrives in Phase 6. Do not describe
/// this storage as secure until then.
class DocumentStore {
  static const _indexName = 'index.json';
  static const _databaseName = 'docnest.sqlite';

  Future<AppDatabase>? _opening;

  Future<Directory> _root() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/documents');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Opens the database once per store. The first open also moves Phase 2 JSON data in
  /// and fills in content hashes for documents that do not have one yet.
  Future<AppDatabase> _database() => _opening ??= _open();

  Future<AppDatabase> _open() async {
    final root = await _root();
    final db = openAppDatabase(File('${root.path}/$_databaseName'));
    await _migrateJsonIndex(db, root);
    await _backfillHashes(db, root);
    return db;
  }

  // ---- Documents ----

  /// All documents, including archived ones, newest first, with their tags.
  Future<List<DocumentRecord>> loadAll() async {
    final db = await _database();
    final rows = await (db.select(db.documentRows)
          ..orderBy([(row) => OrderingTerm.desc(row.addedAt)]))
        .get();

    final tagRows = await db.select(db.documentTags).get();
    final tagsByDocument = <String, List<String>>{};
    for (final tag in tagRows) {
      tagsByDocument.putIfAbsent(tag.documentId, () => <String>[]).add(tag.tagName);
    }

    return [
      for (final row in rows) _fromRow(row, tagsByDocument[row.id] ?? const <String>[]),
    ];
  }

  /// Copies [sourcePath] into private storage and adds it to the database.
  ///
  /// Returns null, and copies nothing, when a file with the same content is already
  /// in DocNest. The caller counts it as a duplicate.
  Future<DocumentRecord?> add({
    required String sourcePath,
    required String originalName,
    required DocumentKind kind,
  }) async {
    final root = await _root();
    final source = File(sourcePath);
    final hash = await _hashFile(source);
    if (await _existsWithHash(hash)) return null;

    final id = _newId();
    final storedName = '$id.${fileExtensionOf(originalName)}';
    final size = await source.length();
    await source.copy('${root.path}/$storedName');

    return _insert(
      DocumentRecord(
        id: id,
        name: originalName,
        storedFileName: storedName,
        kind: kind,
        sizeBytes: size,
        addedAt: DateTime.now(),
      ),
      contentHash: hash,
    );
  }

  /// Saves in-memory bytes (for example a PDF built from scan pages) as a new record.
  Future<DocumentRecord> addBytes({
    required Uint8List bytes,
    required String originalName,
    required DocumentKind kind,
  }) async {
    final root = await _root();
    final id = _newId();
    final storedName = '$id.${fileExtensionOf(originalName)}';

    await File('${root.path}/$storedName').writeAsBytes(bytes, flush: true);

    return _insert(
      DocumentRecord(
        id: id,
        name: originalName,
        storedFileName: storedName,
        kind: kind,
        sizeBytes: bytes.length,
        addedAt: DateTime.now(),
      ),
      contentHash: sha256.convert(bytes).toString(),
    );
  }

  Future<void> setFavorite(DocumentRecord record, {required bool value}) async {
    final db = await _database();
    await (db.update(db.documentRows)..where((row) => row.id.equals(record.id)))
        .write(DocumentRowsCompanion(isFavorite: Value(value)));
  }

  Future<void> setArchived(DocumentRecord record, {required bool value}) async {
    final db = await _database();
    await (db.update(db.documentRows)..where((row) => row.id.equals(record.id)))
        .write(DocumentRowsCompanion(isArchived: Value(value)));
  }

  /// Changes the display name only. The stored file keeps its id-based name.
  Future<void> rename(DocumentRecord record, String name) async {
    final db = await _database();
    await (db.update(db.documentRows)..where((row) => row.id.equals(record.id)))
        .write(DocumentRowsCompanion(name: Value(name)));
  }

  /// Puts the document in [folderId], or takes it out of its folder when null.
  Future<void> moveToFolder(DocumentRecord record, String? folderId) async {
    final db = await _database();
    await (db.update(db.documentRows)..where((row) => row.id.equals(record.id)))
        .write(DocumentRowsCompanion(folderId: Value(folderId)));
  }

  Future<void> addTag(DocumentRecord record, String tag) async {
    final db = await _database();
    await db.into(db.documentTags).insert(
          DocumentTagsCompanion.insert(documentId: record.id, tagName: tag),
          mode: InsertMode.insertOrIgnore,
        );
  }

  Future<void> removeTag(DocumentRecord record, String tag) async {
    final db = await _database();
    await (db.delete(db.documentTags)
          ..where((t) => t.documentId.equals(record.id) & t.tagName.equals(tag)))
        .go();
  }

  /// Removes the record and its tags first, then the file. A crash in between leaves
  /// only an unused file on disk, never a record that points to a missing file.
  Future<void> remove(DocumentRecord record) async {
    final db = await _database();
    await db.transaction(() async {
      await (db.delete(db.documentTags)..where((t) => t.documentId.equals(record.id))).go();
      await (db.delete(db.documentRows)..where((row) => row.id.equals(record.id))).go();
    });

    final root = await _root();
    final file = File('${root.path}/${record.storedFileName}');
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// File on disk for a record, used by previews and sharing.
  Future<File> fileFor(DocumentRecord record) async {
    final root = await _root();
    return File('${root.path}/${record.storedFileName}');
  }

  // ---- Folders ----

  /// Built-in folders first (in name order), then user folders by name.
  Future<List<FolderRecord>> loadFolders() async {
    final db = await _database();
    final rows = await (db.select(db.folders)
          ..orderBy([
            (f) => OrderingTerm.desc(f.isBuiltIn),
            (f) => OrderingTerm.asc(f.name),
          ]))
        .get();
    return [
      for (final row in rows)
        FolderRecord(
          id: row.id,
          name: row.name,
          isBuiltIn: row.isBuiltIn,
          createdAt: row.createdAt,
        ),
    ];
  }

  Future<void> createFolder(String name) async {
    final db = await _database();
    await db.into(db.folders).insert(
          FoldersCompanion.insert(
            id: _newId(),
            name: name,
            createdAt: DateTime.now(),
          ),
        );
  }

  Future<void> renameFolder(FolderRecord folder, String name) async {
    if (folder.isBuiltIn) return;
    final db = await _database();
    await (db.update(db.folders)..where((f) => f.id.equals(folder.id)))
        .write(FoldersCompanion(name: Value(name)));
  }

  /// Documents in the folder are kept. They become unfiled. Personal filing rules that
  /// point to the folder are removed, since they would suggest a folder that is gone.
  Future<void> deleteFolder(FolderRecord folder) async {
    if (folder.isBuiltIn) return;
    final db = await _database();
    await db.transaction(() async {
      await (db.update(db.documentRows)..where((row) => row.folderId.equals(folder.id)))
          .write(const DocumentRowsCompanion(folderId: Value<String?>(null)));
      await (db.delete(db.filingRules)..where((r) => r.folderId.equals(folder.id))).go();
      await (db.delete(db.folders)..where((f) => f.id.equals(folder.id))).go();
    });
  }

  // ---- Personal filing rules ----

  /// Personal rules, newest first.
  Future<List<FilingRuleRecord>> loadFilingRules() async {
    final db = await _database();
    final rows = await (db.select(db.filingRules)
          ..orderBy([(r) => OrderingTerm.desc(r.createdAt)]))
        .get();
    return [
      for (final row in rows)
        FilingRuleRecord(
          keyword: row.keyword,
          folderId: row.folderId,
          enabled: row.enabled,
          createdAt: row.createdAt,
        ),
    ];
  }

  /// Saves a rule. A keyword that already has a rule gets the new folder and is turned on.
  Future<void> saveFilingRule({required String keyword, required String folderId}) async {
    final db = await _database();
    await db.into(db.filingRules).insertOnConflictUpdate(
          FilingRulesCompanion.insert(
            keyword: keyword,
            folderId: folderId,
            enabled: const Value(true),
            createdAt: DateTime.now(),
          ),
        );
  }

  Future<void> setFilingRuleEnabled(FilingRuleRecord rule, {required bool value}) async {
    final db = await _database();
    await (db.update(db.filingRules)..where((r) => r.keyword.equals(rule.keyword)))
        .write(FilingRulesCompanion(enabled: Value(value)));
  }

  Future<void> deleteFilingRule(FilingRuleRecord rule) async {
    final db = await _database();
    await (db.delete(db.filingRules)..where((r) => r.keyword.equals(rule.keyword))).go();
  }

  // ---- Duplicates and hashes ----

  /// SHA-256 of a file, read in chunks so large PDFs are not loaded into memory.
  Future<String> _hashFile(File file) async {
    final digest = await sha256.bind(file.openRead()).first;
    return digest.toString();
  }

  Future<bool> _existsWithHash(String hash) async {
    final db = await _database();
    final matches = await (db.select(db.documentRows)
          ..where((row) => row.contentHash.equals(hash))
          ..limit(1))
        .get();
    return matches.isNotEmpty;
  }

  /// Fills in the hash for documents that were saved before version 3. Files that
  /// are missing on disk are skipped.
  Future<void> _backfillHashes(AppDatabase db, Directory root) async {
    final missing = await (db.select(db.documentRows)
          ..where((row) => row.contentHash.isNull()))
        .get();
    for (final row in missing) {
      final file = File('${root.path}/${row.storedFileName}');
      if (!await file.exists()) continue;
      final hash = await _hashFile(file);
      await (db.update(db.documentRows)..where((r) => r.id.equals(row.id))).write(
        DocumentRowsCompanion(contentHash: Value(hash)),
      );
    }
  }

  // ---- Migration and helpers ----

  Future<DocumentRecord> _insert(DocumentRecord record, {String? contentHash}) async {
    final db = await _database();
    await db.into(db.documentRows).insert(_toCompanion(record, contentHash: contentHash));
    return record;
  }

  /// One-time move of the Phase 2 JSON index into the database. The index file is
  /// renamed afterwards so it is not read again. insertOrIgnore makes a retry safe.
  Future<void> _migrateJsonIndex(AppDatabase db, Directory root) async {
    final index = File('${root.path}/$_indexName');
    if (!await index.exists()) return;

    final raw = jsonDecode(await index.readAsString()) as List<dynamic>;
    final companions = [
      for (final e in raw) _toCompanion(DocumentRecord.fromJson(e as Map<String, dynamic>)),
    ];
    await db.batch((b) {
      b.insertAll(db.documentRows, companions, mode: InsertMode.insertOrIgnore);
    });
    await index.rename('${root.path}/$_indexName.migrated');
  }

  DocumentRowsCompanion _toCompanion(DocumentRecord r, {String? contentHash}) {
    return DocumentRowsCompanion.insert(
      id: r.id,
      name: r.name,
      storedFileName: r.storedFileName,
      kind: r.kind.name,
      sizeBytes: r.sizeBytes,
      addedAt: r.addedAt,
      isFavorite: Value(r.isFavorite),
      isArchived: Value(r.isArchived),
      folderId: Value(r.folderId),
      contentHash: Value(contentHash),
    );
  }

  DocumentRecord _fromRow(DocumentRow row, List<String> tags) {
    return DocumentRecord(
      id: row.id,
      name: row.name,
      storedFileName: row.storedFileName,
      kind: DocumentKind.values.byName(row.kind),
      sizeBytes: row.sizeBytes,
      addedAt: row.addedAt,
      isFavorite: row.isFavorite,
      isArchived: row.isArchived,
      folderId: row.folderId,
      tags: tags,
    );
  }

  String _newId() {
    final random = Random.secure();
    final suffix = List<int>.generate(8, (_) => random.nextInt(256))
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
    return '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}$suffix';
  }
}

final documentStoreProvider = Provider<DocumentStore>((ref) => DocumentStore());
