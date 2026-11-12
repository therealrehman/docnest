import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';

import '../constants/default_categories.dart';

// Generated file. Create it with: dart run build_runner build --delete-conflicting-outputs
part 'app_database.g.dart';

/// One row per imported or scanned file. The files stay on disk in the documents
/// folder; this table keeps their details.
class DocumentRows extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get storedFileName => text()();

  /// The DocumentKind name: 'pdf' or 'image'.
  TextColumn get kind => text()();
  IntColumn get sizeBytes => integer()();
  DateTimeColumn get addedAt => dateTime()();
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();

  /// Folder id, or null when the document is not in a folder.
  TextColumn get folderId => text().nullable()();

  /// SHA-256 of the file content, used for duplicate checks. Null for documents
  /// saved before version 3 until their hash is filled in on the next open.
  TextColumn get contentHash => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Folders. Built-in folders stand for the default categories and cannot be
/// renamed or deleted.
class Folders extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  BoolColumn get isBuiltIn => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Tags on a document. A tag is just its text; there is no separate tag table.
class DocumentTags extends Table {
  TextColumn get documentId => text()();
  TextColumn get tagName => text()();

  @override
  Set<Column> get primaryKey => {documentId, tagName};
}

/// Personal filing rules, made from the user's own corrections to a suggestion.
/// The keyword is the key, so one keyword has at most one rule.
class FilingRules extends Table {
  /// Normalized words: lowercase, letters and digits, single spaces.
  TextColumn get keyword => text()();

  /// The folder to suggest. Deleting that folder deletes the rule.
  TextColumn get folderId => text()();
  BoolColumn get enabled => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {keyword};
}

@DriftDatabase(tables: [DocumentRows, Folders, DocumentTags, FilingRules])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  /// Version 2 adds folders, tags and the document folder column.
  /// Version 3 adds the content hash column.
  /// Version 4 adds personal filing rules.
  /// Bump this when a table changes, and add a step to [migration].
  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _seedBuiltInFolders();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.addColumn(documentRows, documentRows.folderId);
            await m.createTable(folders);
            await m.createTable(documentTags);
            await _seedBuiltInFolders();
          }
          if (from < 3) {
            await m.addColumn(documentRows, documentRows.contentHash);
          }
          if (from < 4) {
            await m.createTable(filingRules);
          }
        },
      );

  /// One built-in folder per default category. insertOrIgnore makes this safe to repeat.
  Future<void> _seedBuiltInFolders() async {
    final now = DateTime.now();
    await batch((b) {
      b.insertAll(
        folders,
        [
          for (final category in defaultCategories)
            FoldersCompanion.insert(
              id: builtInFolderId(category.name),
              name: category.name,
              isBuiltIn: const Value(true),
              createdAt: now,
            ),
        ],
        mode: InsertMode.insertOrIgnore,
      );
    });
  }
}

/// Opens the database file in the app's private folder. Queries run on a background isolate.
AppDatabase openAppDatabase(File file) {
  return AppDatabase(NativeDatabase.createInBackground(file));
}
