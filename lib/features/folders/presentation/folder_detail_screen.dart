import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_theme.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/safe_action.dart';
import '../../../shared/widgets/text_prompt_dialog.dart';
import '../../documents/application/documents_controller.dart';
import '../../documents/data/document_record.dart';
import '../../documents/presentation/document_tile.dart';
import '../application/folders_controller.dart';
import '../data/folder_record.dart';

enum _FolderAction { rename, delete }

/// Documents in one folder or category.
class FolderDetailScreen extends ConsumerWidget {
  const FolderDetailScreen({super.key, required this.folderId});

  final String folderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final folders = ref.watch(foldersProvider);

    return folders.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stackTrace) => const Scaffold(
        body: EmptyState(
          icon: Icons.error_outline_rounded,
          title: 'Could not open this folder',
          message: 'Go back and try again.',
        ),
      ),
      data: (items) {
        final folder = _findFolder(items, folderId);
        if (folder == null) {
          return const Scaffold(
            appBar: AppBar(title: Text('Folder')),
            body: EmptyState(
              icon: Icons.search_off_rounded,
              title: 'Folder not found',
              message: 'It may have been deleted.',
            ),
          );
        }
        return _FolderBody(folder: folder);
      },
    );
  }
}

FolderRecord? _findFolder(List<FolderRecord> items, String id) {
  for (final item in items) {
    if (item.id == id) return item;
  }
  return null;
}

class _FolderBody extends ConsumerWidget {
  const _FolderBody({required this.folder});

  final FolderRecord folder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docs = ref.watch(documentsProvider).valueOrNull ?? const <DocumentRecord>[];
    final inFolder = docs.where((d) => d.folderId == folder.id && !d.isArchived).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(folder.name),
        actions: [
          // Built-in categories cannot be renamed or deleted.
          if (!folder.isBuiltIn)
            PopupMenuButton<_FolderAction>(
              tooltip: 'Folder options',
              onSelected: (action) {
                switch (action) {
                  case _FolderAction.rename:
                    _rename(context, ref);
                  case _FolderAction.delete:
                    _delete(context, ref);
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: _FolderAction.rename, child: Text('Rename')),
                PopupMenuItem(value: _FolderAction.delete, child: Text('Delete folder')),
              ],
            ),
        ],
      ),
      body: inFolder.isEmpty
          ? const EmptyState(
              icon: Icons.folder_open_rounded,
              title: 'This folder is empty',
              message: 'Open a document and choose this folder under Folder.',
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                DocNestSpacing.screen,
                DocNestSpacing.s,
                DocNestSpacing.screen,
                DocNestSpacing.section,
              ),
              itemCount: inFolder.length,
              separatorBuilder: (context, index) => const SizedBox(height: DocNestSpacing.s),
              itemBuilder: (context, index) {
                final record = inFolder[index];
                return DocumentTile(
                  record: record,
                  onTap: () => context.push(AppRoutes.documentDetails(record.id)),
                );
              },
            ),
    );
  }

  Future<void> _rename(BuildContext context, WidgetRef ref) async {
    final typed = await showTextPrompt(
      context,
      title: 'Rename folder',
      initialText: folder.name,
      maxLength: 40,
    );
    final name = typed?.trim() ?? '';
    if (name.isEmpty || name == folder.name) return;
    await runSafely(
      context,
      () => ref.read(foldersProvider.notifier).rename(folder, name),
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Delete "${folder.name}"?'),
        content: const Text(
          'Documents in this folder are not deleted. They are only removed from the folder.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text('Delete', style: TextStyle(color: context.palette.error)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await runSafely(context, () => ref.read(foldersProvider.notifier).delete(folder));
    if (!context.mounted) return;
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.folders);
    }
  }
}
