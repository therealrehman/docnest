import 'package:docnest/features/documents/application/document_filter.dart';
import 'package:docnest/features/documents/data/document_record.dart';
import 'package:flutter_test/flutter_test.dart';

DocumentRecord _doc(
  String id,
  String name, {
  DocumentKind kind = DocumentKind.pdf,
  bool isFavorite = false,
  bool isArchived = false,
  String? folderId,
  List<String> tags = const [],
}) {
  return DocumentRecord(
    id: id,
    name: name,
    storedFileName: '$id.pdf',
    kind: kind,
    sizeBytes: 1,
    addedAt: DateTime(2026),
    isFavorite: isFavorite,
    isArchived: isArchived,
    folderId: folderId,
    tags: tags,
  );
}

List<String> _ids(List<DocumentRecord> docs) => docs.map((d) => d.id).toList();

void main() {
  final items = [
    _doc('1', 'Passport.pdf', tags: ['travel']),
    _doc('2', 'Gas bill.jpg', kind: DocumentKind.image, folderId: 'builtin-bills'),
    _doc('3', 'Old lease.pdf', isArchived: true, tags: ['home']),
    _doc('4', 'Fav.pdf', isFavorite: true),
  ];
  final folderNames = {'builtin-bills': 'Bills'};

  test('default view hides archived documents', () {
    final result = filterDocuments(items, const DocumentQuery(), folderNames);
    expect(_ids(result), ['1', '2', '4']);
  });

  test('search matches name, tag and folder name, ignoring case', () {
    expect(_ids(filterDocuments(items, const DocumentQuery(text: 'PASS'), folderNames)), ['1']);
    expect(_ids(filterDocuments(items, const DocumentQuery(text: 'travel'), folderNames)), ['1']);
    expect(_ids(filterDocuments(items, const DocumentQuery(text: 'bills'), folderNames)), ['2']);
  });

  test('type and view filters work', () {
    expect(
      _ids(filterDocuments(items, const DocumentQuery(type: TypeFilter.image), folderNames)),
      ['2'],
    );
    expect(
      _ids(filterDocuments(items, const DocumentQuery(view: DocumentView.archived), folderNames)),
      ['3'],
    );
  });

  test('tag filter keeps only documents with that tag', () {
    expect(
      _ids(filterDocuments(items, const DocumentQuery(tag: 'travel'), folderNames)),
      ['1'],
    );
  });

  test('activeTags lists tags of non-archived documents only', () {
    expect(activeTags(items), ['travel']);
  });
}
