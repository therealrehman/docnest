import '../data/document_record.dart';

/// Which set of documents the Documents tab shows.
enum DocumentView { all, favorites, archived }

/// Which file type to show.
enum TypeFilter { any, pdf, image }

/// Everything the Documents tab filters by.
class DocumentQuery {
  const DocumentQuery({
    this.view = DocumentView.all,
    this.text = '',
    this.type = TypeFilter.any,
    this.tag,
  });

  final DocumentView view;

  /// Search text. Matches document name, tag text and folder name.
  final String text;

  final TypeFilter type;

  /// Only documents with this tag. Null means no tag filter.
  final String? tag;
}

/// Documents that match [query], in the order given.
///
/// [folderNames] maps folder id to folder name, so search also finds documents
/// by folder name.
List<DocumentRecord> filterDocuments(
  List<DocumentRecord> items,
  DocumentQuery query,
  Map<String, String> folderNames,
) {
  final needle = query.text.trim().toLowerCase();

  return items.where((doc) {
    if (!_inView(doc, query.view)) return false;
    if (query.type == TypeFilter.pdf && doc.kind != DocumentKind.pdf) return false;
    if (query.type == TypeFilter.image && doc.kind != DocumentKind.image) return false;
    if (query.tag != null && !doc.tags.contains(query.tag)) return false;
    if (needle.isEmpty) return true;

    final folderName = doc.folderId == null ? '' : (folderNames[doc.folderId] ?? '');
    return doc.name.toLowerCase().contains(needle) ||
        folderName.toLowerCase().contains(needle) ||
        doc.tags.any((tag) => tag.contains(needle));
  }).toList();
}

/// Archived documents are hidden from All and Favorites.
bool _inView(DocumentRecord doc, DocumentView view) {
  return switch (view) {
    DocumentView.all => !doc.isArchived,
    DocumentView.favorites => doc.isFavorite && !doc.isArchived,
    DocumentView.archived => doc.isArchived,
  };
}

/// Distinct tags on documents that are not archived, sorted.
List<String> activeTags(List<DocumentRecord> items) {
  final tags = <String>{};
  for (final doc in items) {
    if (!doc.isArchived) tags.addAll(doc.tags);
  }
  return tags.toList()..sort();
}
