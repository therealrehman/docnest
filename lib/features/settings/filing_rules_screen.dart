import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_theme.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/safe_action.dart';
import '../documents/application/filing_rules_controller.dart';
import '../documents/data/filing_rule_record.dart';
import '../folders/application/folders_controller.dart';
import '../folders/data/folder_record.dart';
import '../folders/presentation/folder_tile.dart';

/// Personal filing rules. Each one was made when the user moved a suggested document to
/// another folder and chose to remember that choice.
class FilingRulesScreen extends ConsumerWidget {
  const FilingRulesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final rules = ref.watch(filingRulesProvider);
    final folders = ref.watch(foldersProvider).valueOrNull ?? const <FolderRecord>[];

    return Scaffold(
      appBar: AppBar(title: const Text('Filing rules')),
      body: rules.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => const Padding(
          padding: EdgeInsets.all(DocNestSpacing.screen),
          child: EmptyState(
            icon: Icons.error_outline_rounded,
            title: 'Could not load rules',
            message: 'Go back and try again.',
          ),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(DocNestSpacing.screen),
              child: EmptyState(
                icon: Icons.tune_rounded,
                title: 'No filing rules yet',
                message: 'When you move a suggested document to a different folder, '
                    'DocNest can remember that choice for file names with the same word.',
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(
              DocNestSpacing.screen,
              DocNestSpacing.s,
              DocNestSpacing.screen,
              DocNestSpacing.section,
            ),
            children: [
              Text(
                'DocNest suggests the folder when a file name has the word. '
                'Nothing moves until you confirm.',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: DocNestSpacing.m),
              for (final rule in items)
                _RuleTile(rule: rule, folder: _folderById(folders, rule.folderId)),
            ],
          );
        },
      ),
    );
  }

  FolderRecord? _folderById(List<FolderRecord> folders, String id) {
    for (final folder in folders) {
      if (folder.id == id) return folder;
    }
    return null;
  }
}

class _RuleTile extends ConsumerWidget {
  const _RuleTile({required this.rule, required this.folder});

  final FilingRuleRecord rule;
  final FolderRecord? folder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final palette = context.palette;
    final target = folder;

    return Padding(
      padding: const EdgeInsets.only(bottom: DocNestSpacing.s),
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          DocNestSpacing.m,
          DocNestSpacing.xs,
          DocNestSpacing.xs,
          DocNestSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: palette.elevatedSurface,
          borderRadius: BorderRadius.circular(DocNestSpacing.radiusCard),
          border: Border.all(color: palette.border),
        ),
        child: Row(
          children: [
            Icon(
              target == null ? Icons.help_outline_rounded : folderIconFor(target),
              color: DocNestColors.primaryBlue,
            ),
            const SizedBox(width: DocNestSpacing.s),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('“${rule.keyword}”', style: theme.textTheme.titleMedium),
                  Text(
                    target == null ? 'Folder no longer exists' : 'Suggests ${target.name}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Switch(
              value: rule.enabled,
              onChanged: (value) => runSafely(
                context,
                () => ref.read(filingRulesProvider.notifier).setEnabled(rule, value: value),
              ),
            ),
            IconButton(
              tooltip: 'Delete rule',
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: () => _confirmDelete(context, ref, target?.name),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, String? folderName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete this rule?'),
        content: Text(
          'DocNest will stop suggesting ${folderName ?? 'this folder'} for '
          '“${rule.keyword}”. Your documents are not changed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: context.palette.error),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    await runSafely(
      context,
      () => ref.read(filingRulesProvider.notifier).delete(rule),
    );
  }
}
