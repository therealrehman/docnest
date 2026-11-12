import 'package:docnest/core/constants/default_categories.dart';
import 'package:docnest/features/documents/application/category_rules.dart';
import 'package:docnest/features/documents/data/filing_rule_record.dart';
import 'package:flutter_test/flutter_test.dart';

FilingRuleRecord _rule(String keyword, String folderId, {bool enabled = true}) {
  return FilingRuleRecord(
    keyword: keyword,
    folderId: folderId,
    enabled: enabled,
    createdAt: DateTime(2026),
  );
}

void main() {
  test('file names suggest the expected built-in folder', () {
    expect(suggestedFolderIdFor('Passport - Ayesha.pdf'), 'builtin-identity-travel');
    expect(suggestedFolderIdFor('Electricity bill March.pdf'), 'builtin-bills');
    expect(suggestedFolderIdFor('Insurance claim form.pdf'), 'builtin-insurance');
    expect(suggestedFolderIdFor('Warranty card.jpg'), 'builtin-warranty-purchases');
    expect(suggestedFolderIdFor('PAYSLIP-2026-10.pdf'), 'builtin-work-employment');
  });

  test('no keyword match means no suggestion', () {
    expect(suggestedFolderIdFor('holiday photo.jpg'), isNull);
  });

  test('every suggestion points to a real default category', () {
    final validIds = {for (final c in defaultCategories) builtInFolderId(c.name)};
    for (final name in ['passport.pdf', 'bill.pdf', 'lease.pdf', 'payslip.pdf']) {
      final id = suggestedFolderIdFor(name);
      expect(id, isNotNull);
      expect(validIds.contains(id), isTrue);
    }
  });

  test('keywords match whole words only', () {
    expect(suggestedFolderIdFor('Please find attached.pdf'), isNull); // "lease"
    expect(suggestedFolderIdFor('Release notes.pdf'), isNull); // "lease"
    expect(suggestedFolderIdFor('Needed documents.pdf'), isNull); // "deed"
    expect(suggestedFolderIdFor('Advisable reading.pdf'), isNull); // "visa"
  });

  test('plural forms still match', () {
    expect(suggestedFolderIdFor('Bills March.pdf'), 'builtin-bills');
    expect(suggestedFolderIdFor('Receipts.pdf'), 'builtin-warranty-purchases');
  });

  test('a file that fits two folders gets a medium suggestion', () {
    final suggestion = suggestFolder(fileName: 'Bill insurance.pdf');
    expect(suggestion.confidence, SuggestionConfidence.medium);
    expect(suggestion.clearFolderId, isNull);
    expect(
      suggestion.possibleFolderIds,
      containsAll(['builtin-bills', 'builtin-insurance']),
    );
  });

  test('one clear keyword match is a high confidence suggestion', () {
    final suggestion = suggestFolder(fileName: 'Passport - Ayesha.pdf');
    expect(suggestion.confidence, SuggestionConfidence.high);
    expect(suggestion.clearFolderId, 'builtin-identity-travel');
  });

  test('a personal rule alone gives a medium suggestion', () {
    final suggestion = suggestFolder(
      fileName: 'EPB March.pdf',
      personalRules: [_rule('epb', 'builtin-bills')],
    );
    expect(suggestion.confidence, SuggestionConfidence.medium);
    expect(suggestion.possibleFolderIds, ['builtin-bills']);
    expect(suggestion.candidates.single.score, personalRuleWeight);
  });

  test('a personal rule adds points to a built-in match', () {
    final suggestion = suggestFolder(
      fileName: 'Electricity bill.pdf',
      personalRules: [_rule('electricity', 'builtin-finance')],
    );
    expect(suggestion.clearFolderId, 'builtin-bills'); // 30 against 10
    expect(suggestion.candidates.last.folderId, 'builtin-finance');
    expect(suggestion.candidates.last.score, personalRuleWeight);
  });

  test('disabled personal rules are ignored', () {
    final suggestion = suggestFolder(
      fileName: 'EPB March.pdf',
      personalRules: [_rule('epb', 'builtin-bills', enabled: false)],
    );
    expect(suggestion.candidates, isEmpty);
  });

  test('a CNIC number suggests identity, but a timestamp does not', () {
    final cnic = suggestFolder(fileName: 'Scan 35202-1234567-1.jpg');
    expect(cnic.confidence, SuggestionConfidence.medium);
    expect(cnic.possibleFolderIds, ['builtin-identity-travel']);
    expect(cnic.candidates.single.score, patternWeight);
    expect(suggestedFolderIdFor('1699999999999.jpg'), isNull);
  });

  test('OCR text adds points when it is passed in', () {
    final suggestion = suggestFolder(
      fileName: 'scan 0031.pdf',
      ocrText: 'Monthly electricity bill',
    );
    expect(suggestion.clearFolderId, 'builtin-bills');
    expect(suggestion.candidates.single.score, ocrKeywordWeight);
  });

  test('names are normalized before matching', () {
    expect(normalizeForMatching('  EPB-Bill!!  '), 'epb bill');
    expect(normalizeForMatching('PAYSLIP_2026-10.pdf'), 'payslip 2026 10 pdf');
  });

  test('rule keyword skips numbers, months and file types', () {
    expect(suggestedRuleKeyword('Scan_2026-03 EPB March copy.pdf'), 'epb');
    expect(suggestedRuleKeyword('Passport - Ayesha.pdf'), 'passport');
    expect(suggestedRuleKeyword('scan 2026.pdf'), isNull);
  });
}
