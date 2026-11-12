/// A personal filing rule, made from a correction the user made to a suggestion.
/// When a file name (or OCR text, once OCR exists) contains [keyword] as whole words,
/// DocNest suggests [folderId]. A rule never moves a document by itself.
class FilingRuleRecord {
  const FilingRuleRecord({
    required this.keyword,
    required this.folderId,
    required this.enabled,
    required this.createdAt,
  });

  /// Normalized words: lowercase, letters and digits, single spaces. One rule per keyword.
  final String keyword;

  /// The folder to suggest.
  final String folderId;

  /// Disabled rules are kept but never used for suggestions.
  final bool enabled;
  final DateTime createdAt;
}
