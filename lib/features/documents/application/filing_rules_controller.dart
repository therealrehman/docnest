import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/document_store.dart';
import '../data/filing_rule_record.dart';
import 'category_rules.dart';

/// Personal filing rules. Every change goes through the store, then the list reloads.
class FilingRulesController extends AsyncNotifier<List<FilingRuleRecord>> {
  @override
  Future<List<FilingRuleRecord>> build() {
    return ref.read(documentStoreProvider).loadFilingRules();
  }

  /// Saves a rule that suggests [folderId] for names with [keyword]. The keyword is cleaned
  /// first. Returns false, and saves nothing, when no words are left after cleaning.
  Future<bool> saveRule({required String keyword, required String folderId}) async {
    final cleaned = normalizeForMatching(keyword);
    if (cleaned.isEmpty) return false;

    final store = ref.read(documentStoreProvider);
    await store.saveFilingRule(keyword: cleaned, folderId: folderId);
    state = await AsyncValue.guard(store.loadFilingRules);
    return true;
  }

  Future<void> setEnabled(FilingRuleRecord rule, {required bool value}) =>
      _change((store) => store.setFilingRuleEnabled(rule, value: value));

  Future<void> delete(FilingRuleRecord rule) =>
      _change((store) => store.deleteFilingRule(rule));

  Future<void> _change(Future<void> Function(DocumentStore store) action) async {
    final store = ref.read(documentStoreProvider);
    await action(store);
    state = await AsyncValue.guard(store.loadFilingRules);
  }
}

final filingRulesProvider =
    AsyncNotifierProvider<FilingRulesController, List<FilingRuleRecord>>(
  FilingRulesController.new,
);
