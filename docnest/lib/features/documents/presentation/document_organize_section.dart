import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../shared/widgets/safe_action.dart';
import '../../../shared/widgets/text_prompt_dialog.dart';
import '../../folders/application/folders_controller.dart';
import '../../folders/data/folder_record.dart';
import '../../folders/presentation/folder_tile.dart';
import '../application/category_rules.dart';
import '../application/documents_controller.dart';
import '../application/filing_rules_controller.dart';
import '../data/document_record.dart';
import '../data/filing_rule_record.dart';

const _noFolder = '';
const _maxTagLength = 24;
const _maxRuleLength = 40;

/// Folder and tag editor shown on the document details screen.
class DocumentOrganizeSection extends ConsumerWidget {
  const DocumentOrganizeSection({super.key, required this.record});

  final DocumentRecord record;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final folders = ref.watch(foldersProvider).valueOrNull ?? const <FolderRecord>[];
    final rules = ref.watch(filingRulesProvider).valueOrNull ?? const <FilingRuleRecord>[];
    final current = _folderById(folders, record.folderId);

    // Suggestions are shown only for documents that are not filed yet.
    final suggestion = record.folderId == null
        ? suggestFolder(fileName: record.name, personalRules: rules)
        : null;
    final clear = _folderById(folders, suggestion?.clearFolderId);
    final possible = _foldersFor(folders, suggestion?.possibleFolderIds ?? const <String>[]);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Folder', style: theme.textTheme.titleMedium),
        const SizedBox(height: DocNestSpacing.xs),
        if (clear != null) ...[
          ActionChip(
            avatar: const Icon(Icons.auto_awesome_outlined, size: 18),
            label: Text('Suggested: ${clear.name}'),
            onPressed: () => _moveTo(context, ref, clear, suggestion),
          ),
          const SizedBox(height: DocNestSpacing.xs),
        ] else if (possible.isNotEmpty) ...[
          Text('Possible folders', style: theme.textTheme.bodySmall),
          const SizedBox(height: DocNestSpacing.xs),
          Wrap(
            spacing: DocNestSpacing.xs,
            runSpacing: DocNestSpacing.xs,
            children: [
              for (final folder in possible)
                ActionChip(
                  avatar: Icon(folderIconFor(folder), size: 18),
                  label: Text(folder.name),
                  onPressed: () => _moveTo(context, ref, folder, suggestion),
                ),
            ],
          ),
          const SizedBox(height: DocNestSpacing.xs),
        ],
        OutlinedButton.icon(
          onPressed: () => _pickFolder(context, ref, folders, suggestion),
          icon: Icon(current == null ? Icons.folder_off_outlined : folderIconFor(current)),
          label: Text(current?.name ?? 'Not in a folder'),
        ),
        const SizedBox(height: DocNestSpacing.m),
        Text('Tags', style: theme.textTheme.titleMedium),
        const SizedBox(height: DocNestSpacing.xs),
        Wrap(
          spacing: DocNestSpacing.xs,
          runSpacing: DocNestSpacing.xs,
          children: [
            for (final tag in record.tags)
              InputChip(
                label: Text(tag),
                onDeleted: () => runSafely(
                  context,
                  () => ref.read(documentsProvider.notifier).removeTag(record, tag),
                ),
              ),
            ActionChip(
              avatar: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add tag'),
              onPressed: () => _addTag(context, ref),
            ),
          ],
        ),
      ],
    );
  }

  FolderRecord? _folderById(List<FolderRecord> folders, String? id) {
    if (id == null) return null;
    for (final folder in folders) {
      if (folder.id == id) return folder;
    }
    return null;
  }

  /// Folders for [ids] that still exist, in the same order.
  List<FolderRecord> _foldersFor(List<FolderRecord> folders, List<String> ids) {
    final result = <FolderRecord>[];
    for (final id in ids) {
      final folder = _folderById(folders, id);
      if (folder != null) result.add(folder);
    }
    return result;
  }

  Future<void> _pickFolder(
    BuildContext context,
    WidgetRef ref,
    List<FolderRecord> folders,
    FilingSuggestion? suggestion,
  ) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              leading: const Icon(Icons.folder_off_outlined),
              title: const Text('Not in a folder'),
              trailing: record.folderId == null ? const Icon(Icons.check_rounded) : null,
              onTap: () => Navigator.of(sheetContext).pop(_noFolder),
            ),
            for (final folder in folders)
              ListTile(
                leading: Icon(folderIconFor(folder)),
                title: Text(folder.name),
                trailing:
                    record.folderId == folder.id ? const Icon(Icons.check_rounded) : null,
                onTap: () => Navigator.of(sheetContext).pop(folder.id),
              ),
          ],
        ),
      ),
    );
    if (choice == null || !context.mounted) return;

    final folder = choice == _noFolder ? null : _folderById(folders, choice);
    if (choice != _noFolder && folder == null) return;
    await _moveTo(context, ref, folder, suggestion);
  }

  /// Moves the document into [folder]; null means no folder. When the user picks a folder
  /// that the suggestion did not offer, asks whether to remember that choice as a rule.
  Future<void> _moveTo(
    BuildContext context,
    WidgetRef ref,
    FolderRecord? folder,
    FilingSuggestion? suggestion,
  ) async {
    var moved = false;
    await runSafely(context, () async {
      await ref.read(documentsProvider.notifier).moveToFolder(record, folder?.id);
      moved = true;
    });

    if (!moved || folder == null || suggestion == null || suggestion.candidates.isEmpty) {
      return;
    }
    final offered = suggestion.candidates.any((candidate) => candidate.folderId == folder.id);
    if (offered || !context.mounted) return;
    await _offerRule(context, ref, folder);
  }

  /// Asks whether file names with a word from this one should suggest [folder] in future.
  Future<void> _offerRule(BuildContext context, WidgetRef ref, FolderRecord folder) async {
    final typed = await showTextPrompt(
      context,
      title: 'Always suggest ${folder.name}?',
      message: 'Future files with this word in their name will be suggested for '
          '${folder.name}. Nothing moves until you confirm.',
      initialText: suggestedRuleKeyword(record.name) ?? '',
      hint: 'Word from the file name',
      confirmLabel: 'Save rule',
      maxLength: _maxRuleLength,
    );
    if (typed == null || !context.mounted) return;

    final cleaned = normalizeForMatching(typed);
    if (cleaned.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a word from the file name.')),
      );
      return;
    }

    var saved = false;
    await runSafely(context, () async {
      saved = await ref
          .read(filingRulesProvider.notifier)
          .saveRule(keyword: cleaned, folderId: folder.id);
    });
    if (saved && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Rule saved: "$cleaned" suggests ${folder.name}.')),
      );
    }
  }

  Future<void> _addTag(BuildContext context, WidgetRef ref) async {
    final typed = await showTextPrompt(
      context,
      title: 'Add tag',
      hint: 'For example: tax, 2026',
      confirmLabel: 'Add',
      maxLength: _maxTagLength,
    );
    if (typed == null) return;

    final tag = typed.trim().toLowerCase();
    if (tag.isEmpty || record.tags.contains(tag)) return;
    await runSafely(
      context,
      () => ref.read(documentsProvider.notifier).addTag(record, tag),
    );
  }
}
