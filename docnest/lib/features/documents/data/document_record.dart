/// Document kinds supported so far (PDF and common images).
enum DocumentKind { pdf, image }

const _imageExtensions = {'jpg', 'jpeg', 'png', 'webp'};

/// Extensions offered by the file picker.
const supportedExtensions = ['pdf', 'jpg', 'jpeg', 'png', 'webp'];

/// Lowercase extension without the dot, or '' when there is none.
String fileExtensionOf(String fileName) {
  final dot = fileName.lastIndexOf('.');
  if (dot < 0 || dot == fileName.length - 1) return '';
  return fileName.substring(dot + 1).toLowerCase();
}

/// Document kind for a file name, or null when the type is not supported.
DocumentKind? kindForFileName(String fileName) {
  final ext = fileExtensionOf(fileName);
  if (ext == 'pdf') return DocumentKind.pdf;
  if (_imageExtensions.contains(ext)) return DocumentKind.image;
  return null;
}

class DocumentRecord {
  const DocumentRecord({
    required this.id,
    required this.name,
    required this.storedFileName,
    required this.kind,
    required this.sizeBytes,
    required this.addedAt,
    this.isFavorite = false,
    this.isArchived = false,
    this.folderId,
    this.tags = const [],
  });

  final String id;

  /// Name as the user chose it. May be renamed.
  final String name;

  /// File name inside DocNest's private documents folder. Never changes after import.
  final String storedFileName;

  final DocumentKind kind;
  final int sizeBytes;
  final DateTime addedAt;
  final bool isFavorite;

  /// Archived documents leave the main list but stay on this phone.
  final bool isArchived;

  /// Folder id, or null when the document is not in a folder.
  final String? folderId;

  /// Tag texts, lowercase, in no particular order.
  final List<String> tags;

  /// Used only to read the Phase 2 JSON index during the one-time migration.
  factory DocumentRecord.fromJson(Map<String, dynamic> json) {
    return DocumentRecord(
      id: json['id'] as String,
      name: json['name'] as String,
      storedFileName: json['storedFileName'] as String,
      kind: DocumentKind.values.byName(json['kind'] as String),
      sizeBytes: json['sizeBytes'] as int,
      addedAt: DateTime.parse(json['addedAt'] as String),
      isFavorite: json['isFavorite'] as bool? ?? false,
      isArchived: json['isArchived'] as bool? ?? false,
    );
  }
}
