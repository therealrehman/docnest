/// A folder. Built-in folders stand for the default categories.
class FolderRecord {
  const FolderRecord({
    required this.id,
    required this.name,
    required this.isBuiltIn,
    required this.createdAt,
  });

  final String id;
  final String name;

  /// Built-in folders cannot be renamed or deleted.
  final bool isBuiltIn;
  final DateTime createdAt;
}
