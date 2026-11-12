import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/document_record.dart';
import '../data/document_store.dart';

/// Result of one import action.
class ImportSummary {
  const ImportSummary({
    required this.imported,
    required this.skipped,
    this.duplicates = 0,
  });

  final int imported;

  /// Unsupported file types.
  final int skipped;

  /// Files whose content is already in DocNest. They are not copied again.
  final int duplicates;
}

/// Holds the list of imported documents and the actions that change it.
class DocumentsController extends AsyncNotifier<List<DocumentRecord>> {
  @override
  Future<List<DocumentRecord>> build() {
    return ref.read(documentStoreProvider).loadAll();
  }

  /// Opens the system picker and copies supported files into private storage.
  Future<ImportSummary> importFromPicker() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: supportedExtensions,
      allowMultiple: true,
    );
    if (result == null) {
      return const ImportSummary(imported: 0, skipped: 0);
    }

    final store = ref.read(documentStoreProvider);
    var imported = 0;
    var skipped = 0;
    var duplicates = 0;

    try {
      for (final file in result.files) {
        final path = file.path;
        final kind = kindForFileName(file.name);
        if (path == null || kind == null) {
          skipped++;
          continue;
        }
        final record = await store.add(sourcePath: path, originalName: file.name, kind: kind);
        if (record == null) {
          duplicates++;
        } else {
          imported++;
        }
      }
    } finally {
      // Refresh even when a later file fails, so already-saved files show up.
      if (imported > 0) {
        state = await AsyncValue.guard(store.loadAll);
      }
    }

    return ImportSummary(imported: imported, skipped: skipped, duplicates: duplicates);
  }

  /// Saves a PDF made from scan pages as a new document.
  Future<void> saveScannedPdf({required Uint8List bytes, required String name}) async {
    final store = ref.read(documentStoreProvider);
    final fileName = name.toLowerCase().endsWith('.pdf') ? name : '$name.pdf';
    await store.addBytes(bytes: bytes, originalName: fileName, kind: DocumentKind.pdf);
    state = await AsyncValue.guard(store.loadAll);
  }

  /// Applies one change in storage, then reloads the list.
  Future<void> _change(Future<void> Function(DocumentStore store) action) async {
    final store = ref.read(documentStoreProvider);
    await action(store);
    state = await AsyncValue.guard(store.loadAll);
  }

  Future<void> setFavorite(DocumentRecord record, {required bool value}) =>
      _change((store) => store.setFavorite(record, value: value));

  Future<void> setArchived(DocumentRecord record, {required bool value}) =>
      _change((store) => store.setArchived(record, value: value));

  Future<void> rename(DocumentRecord record, String name) =>
      _change((store) => store.rename(record, name));

  Future<void> moveToFolder(DocumentRecord record, String? folderId) =>
      _change((store) => store.moveToFolder(record, folderId));

  Future<void> addTag(DocumentRecord record, String tag) =>
      _change((store) => store.addTag(record, tag));

  Future<void> removeTag(DocumentRecord record, String tag) =>
      _change((store) => store.removeTag(record, tag));

  Future<void> remove(DocumentRecord record) async {
    final store = ref.read(documentStoreProvider);
    await store.remove(record);
    state = await AsyncValue.guard(store.loadAll);
  }
}

final documentsProvider =
    AsyncNotifierProvider<DocumentsController, List<DocumentRecord>>(
  DocumentsController.new,
);
