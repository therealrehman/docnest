import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/safe_action.dart';
import '../../../shared/widgets/text_prompt_dialog.dart';
import '../../documents/application/documents_controller.dart';
import '../../documents/data/document_record.dart';
import '../application/folders_controller.dart';
import 'folder_tile.dart';

/// Categories and folders. Built-in categories come first, then user folders.
class FoldersScreen extends ConsumerWidget {
  const FoldersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final folders = ref.watch(foldersProvider);
    final documents = ref.watch(documentsProvider).valueOrNull ?? const <DocumentRecord>[];

    return Scaffold(
      appBar: AppBar(title: const Text('Folders')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createFolder(context, ref),
        icon: const Icon(Icons.create_new_folder_outlined),
        label: const Text('New folder'),
      ),
      body: folders.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => const EmptyState(
          icon: Icons.error_outline_rounded,
          title: 'Could not load folders',
          message: 'Go back and try again.',
        ),
        data: (items) => ListView.separated(
          padding: const EdgeInsets.fromLTRB(
            DocNestSpacing.screen,
            DocNestSpacing.s,
            DocNestSpacing.screen,
            96,
          ),
          itemCount: items.length,
          separatorBuilder: (context, index) => const SizedBox(height: DocNestSpacing.s),
          itemBuilder: (context, index) {
            final folder = items[index];
            final count =
                documents.where((d) => d.folderId == folder.id && !d.isArchived).length;
            return FolderTile(
              folder: folder,
              count: count,
              onTap: () => context.push(AppRoutes.folderDetails(folder.id)),
            );
          },
        ),
      ),
    );
  }

  Future<void> _createFolder(BuildContext context, WidgetRef ref) async {
    final typed = await showTextPrompt(
      context,
      title: 'New folder',
      hint: 'Folder name',
      confirmLabel: 'Create',
      maxLength: 40,
    );
    final name = typed?.trim() ?? '';
    if (name.isEmpty) return;
    await runSafely(
      context,
      () => ref.read(foldersProvider.notifier).create(name),
      message: 'Could not create the folder. Please try again.',
    );
  }
}
