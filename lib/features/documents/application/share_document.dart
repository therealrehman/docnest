import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../data/document_record.dart';
import '../data/document_store.dart';

/// Opens the system share sheet with the document. The receiving app can save it
/// (for example to Files or Drive), which is how a copy leaves DocNest.
///
/// A copy with the document's own name is made first, so the receiver sees a
/// readable file name instead of the internal id. The copy stays in the app's
/// temporary cache, which the system may clear.
Future<void> shareDocument(DocumentStore store, DocumentRecord record) async {
  final source = await store.fileFor(record);
  final tempDir = await getTemporaryDirectory();
  final copy = await source.copy('${tempDir.path}/${_safeFileName(record.name)}');

  await Share.shareXFiles(
    [XFile(copy.path, mimeType: _mimeTypeFor(record))],
    subject: record.name,
  );
}

String _safeFileName(String name) {
  final cleaned = name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();
  return cleaned.isEmpty ? 'document' : cleaned;
}

String _mimeTypeFor(DocumentRecord record) {
  if (record.kind == DocumentKind.pdf) return 'application/pdf';
  return switch (fileExtensionOf(record.name)) {
    'png' => 'image/png',
    'webp' => 'image/webp',
    _ => 'image/jpeg',
  };
}
