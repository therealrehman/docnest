import '../../../core/constants/default_categories.dart';
import '../data/filing_rule_record.dart';

// Local, rule-based filing suggestions (blueprint section 21). No cloud or AI service
// is used. Nothing here moves a document: the caller shows the result and the user confirms.
//
// Each folder earns points from the signals that match a document. A signal counts once
// per folder, however many of its keywords match:
//   file name keyword      30
//   OCR text keyword       40  (used only when OCR text is passed in; OCR is not built yet)
//   file name pattern      20  (for example a CNIC number)
//   personal filing rule   10
// These are first-pass weights, not calibrated probabilities.

const filenameKeywordWeight = 30;
const ocrKeywordWeight = 40;
const patternWeight = 20;
const personalRuleWeight = 10;

/// A folder with at least this score, and no close rival, is the one suggestion.
const highConfidenceScore = 30;

/// Lowest score that is shown at all. Below this the document stays unfiled.
const possibleScore = 10;

/// Most folders offered as choices when no single folder leads.
const maxPossibleFolders = 3;

/// Keywords per built-in category. A keyword must appear as whole words, and a plural
/// "s" is allowed, so "lease" does not match "please" but "bills" matches "bill".
const _categoryKeywords = <(String, List<String>)>[
  ('Identity & Travel', ['passport', 'visa', 'aadhaar', 'cnic', 'national id', 'boarding pass']),
  ('Education', ['certificate', 'degree', 'transcript', 'marksheet', 'admission', 'university']),
  ('Health', ['prescription', 'lab report', 'medical', 'vaccination', 'doctor', 'hospital']),
  ('Vehicle', ['vehicle', 'registration', 'driving licence', 'driving license', 'challan']),
  ('Home & Property', ['rent agreement', 'lease', 'property tax', 'deed']),
  ('Insurance', ['insurance']),
  ('Bills', ['bill', 'invoice', 'electricity', 'utility']),
  ('Finance', ['bank statement', 'income tax', 'tax return', 'loan']),
  ('Warranty & Purchases', ['warranty', 'receipt', 'purchase', 'order confirmation']),
  ('Work & Employment', ['offer letter', 'payslip', 'pay slip', 'salary slip', 'employment contract']),
];

/// Identifier formats in file names. Only the match is used; the number is never stored
/// or shown. Dashes are required, so 13-digit timestamps in file names do not match.
final _categoryPatterns = <(String, RegExp)>[
  ('Identity & Travel', RegExp(r'(?<!\d)\d{5}-\d{7}-\d(?!\d)')), // Pakistani CNIC
];

final _nonWordChars = RegExp(r'[^\p{L}\p{N}]+', unicode: true);
final _digitsOnly = RegExp(r'^\d+$');

/// Lowercase words joined by single spaces. Dashes, dots and underscores count as spaces,
/// so "PAYSLIP-2026_10.pdf" becomes "payslip 2026 10 pdf". Letters from other scripts are
/// kept. Used for file names, OCR text and rule keywords alike.
String normalizeForMatching(String text) {
  return text.toLowerCase().replaceAll(_nonWordChars, ' ').trim();
}

/// True when [phrase] appears in [normalized] as whole words. Both must already be
/// normalized.
bool _hasPhrase(String normalized, String phrase) {
  final padded = ' $normalized ';
  return padded.contains(' $phrase ') || padded.contains(' ${phrase}s ');
}

/// Ids of the built-in folders whose keywords appear in [normalized].
List<String> _builtInFoldersWithKeyword(String normalized) {
  if (normalized.isEmpty) return const [];
  return [
    for (final (category, keywords) in _categoryKeywords)
      if (keywords.any((keyword) => _hasPhrase(normalized, keyword)))
        builtInFolderId(category),
  ];
}

/// One folder that might fit a document, with the points behind it.
class FolderCandidate {
  const FolderCandidate({required this.folderId, required this.score});

  final String folderId;
  final int score;
}

enum SuggestionConfidence { high, medium, none }

/// What the engine thinks about one document. [candidates] is sorted best first.
class FilingSuggestion {
  const FilingSuggestion(this.candidates);

  final List<FolderCandidate> candidates;

  /// High: one folder clearly leads, so it is shown as "Suggested".
  /// Medium: several folders are possible, so the user picks one of them.
  /// None: nothing matched, so the document stays unfiled.
  SuggestionConfidence get confidence {
    if (candidates.isEmpty) return SuggestionConfidence.none;
    final leader = candidates.first.score;
    final runnerUp = candidates.length > 1 ? candidates[1].score : 0;
    final isClear = leader >= highConfidenceScore && runnerUp < highConfidenceScore;
    return isClear ? SuggestionConfidence.high : SuggestionConfidence.medium;
  }

  /// The folder to show as "Suggested", or null unless confidence is high.
  String? get clearFolderId =>
      confidence == SuggestionConfidence.high ? candidates.first.folderId : null;

  /// Folder ids to offer as choices, best first, at most [maxPossibleFolders].
  List<String> get possibleFolderIds =>
      [for (final candidate in candidates.take(maxPossibleFolders)) candidate.folderId];
}

/// Suggests folders for one document from its file name, optional OCR text and the
/// user's personal rules. Disabled rules are ignored. Nothing is moved by this function.
FilingSuggestion suggestFolder({
  required String fileName,
  String? ocrText,
  List<FilingRuleRecord> personalRules = const [],
}) {
  final name = normalizeForMatching(fileName);
  final ocr = normalizeForMatching(ocrText ?? '');
  final points = <String, int>{};

  void award(Iterable<String> folderIds, int weight) {
    for (final folderId in folderIds.toSet()) {
      points[folderId] = (points[folderId] ?? 0) + weight;
    }
  }

  award(_builtInFoldersWithKeyword(name), filenameKeywordWeight);
  award(_builtInFoldersWithKeyword(ocr), ocrKeywordWeight);
  award(
    [
      for (final (category, pattern) in _categoryPatterns)
        if (pattern.hasMatch(fileName)) builtInFolderId(category),
    ],
    patternWeight,
  );
  award(
    [
      for (final rule in personalRules)
        if (rule.enabled && (_hasPhrase(name, rule.keyword) || _hasPhrase(ocr, rule.keyword)))
          rule.folderId,
    ],
    personalRuleWeight,
  );

  final candidates = [
    for (final entry in points.entries)
      if (entry.value >= possibleScore)
        FolderCandidate(folderId: entry.key, score: entry.value),
  ]..sort((a, b) {
      final byScore = b.score.compareTo(a.score);
      return byScore != 0 ? byScore : a.folderId.compareTo(b.folderId);
    });

  return FilingSuggestion(candidates);
}

/// Id of the built-in folder that [fileName] suggests with high confidence, or null.
/// Uses the file name only and no personal rules.
String? suggestedFolderIdFor(String fileName) =>
    suggestFolder(fileName: fileName).clearFolderId;

/// Words that make a poor rule on their own: filler, file types, scan labels and months.
const _ruleStopWords = <String>{
  'the', 'and', 'for', 'with', 'copy', 'final', 'new', 'scan', 'scanned', 'file', 'doc',
  'docs', 'document', 'image', 'img', 'photo', 'page', 'version', 'pdf', 'jpg', 'jpeg',
  'png', 'webp', 'jan', 'feb', 'mar', 'apr', 'may', 'jun', 'jul', 'aug', 'sep', 'sept',
  'oct', 'nov', 'dec', 'january', 'february', 'march', 'april', 'june', 'july', 'august',
  'september', 'october', 'november', 'december',
};

/// The word to offer when the user saves a personal rule for [fileName]: the longest word
/// that is not a number, a month, a file type or filler. The user can edit it first.
/// Null when no such word exists.
String? suggestedRuleKeyword(String fileName) {
  String? best;
  for (final word in normalizeForMatching(fileName).split(' ')) {
    if (word.length < 3 || _ruleStopWords.contains(word)) continue;
    if (_digitsOnly.hasMatch(word)) continue;
    if (best == null || word.length > best.length) best = word;
  }
  return best;
}
