import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_theme.dart';
import '../../../shared/formatters/formatters.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/safe_action.dart';
import '../application/documents_controller.dart';
import '../application/share_document.dart';
import '../data/document_record.dart';
import '../data/document_store.dart';
import 'document_organize_section.dart';
import 'document_preview.dart';

/// Preview plus details for one document, with delete.
/// Rename, move, share and export come in later phases.
class DocumentDetailsScreen extends ConsumerWidget {
  const DocumentDetailsScreen({super.key, required this.documentId});

  final String documentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docs = ref.watch(documentsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Document details')),
      body: docs.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => ListView(
          padding: const EdgeInsets.all(DocNestSpacing.screen),
          children: const [
            EmptyState(
              icon: Icons.error_outline_rounded,
              title: 'Could not open this document',
              message: 'Go back and try again.',
            ),
          ],
        ),
        data: (items) {
          final record = _findById(items, documentId);
          if (record == null) {
            return ListView(
              padding: const EdgeInsets.all(DocNestSpacing.screen),
              children: const [
                EmptyState(
                  icon: Icons.search_off_rounded,
                  title: 'Document not found',
                  message: 'It may have been deleted.',
                ),
              ],
            );
          }
          return _DetailsBody(record: record);
        },
      ),
    );
  }
}

DocumentRecord? _findById(List<DocumentRecord> items, String id) {
  for (final item in items) {
    if (item.id == id) return item;
  }
  return null;
}

class _DetailsBody extends ConsumerStatefulWidget {
  const _DetailsBody({required this.record});

  final DocumentRecord record;

  @override
  ConsumerState<_DetailsBody> createState() => _DetailsBodyState();
}

class _DetailsBodyState extends ConsumerState<_DetailsBody> {
  // Resolved once so the preview is not rebuilt on every parent rebuild.
  late final Future<File> _fileFuture =
      ref.read(documentStoreProvider).fileFor(widget.record);

  /// Runs one change. Shows a message instead of failing silently when storage fails.
  Future<void> _run(Future<void> Function() change) async {
    try {
      await change();
    } on Exception {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save the change. Please try again.')),
      );
    }
  }

  Future<void> _toggleFavorite() => _run(() => ref
      .read(documentsProvider.notifier)
      .setFavorite(widget.record, value: !widget.record.isFavorite));

  Future<void> _toggleArchive() => _run(() => ref
      .read(documentsProvider.notifier)
      .setArchived(widget.record, value: !widget.record.isArchived));

  Future<void> _rename() async {
    final typed = await showDialog<String>(
      context: context,
      builder: (_) => _RenameDialog(initialName: widget.record.name),
    );
    if (typed == null || typed.isEmpty || !mounted) return;

    // Keep the file type at the end of the name, for example "Passport.pdf".
    final ext = fileExtensionOf(widget.record.name);
    final name = typed.toLowerCase().endsWith('.$ext') ? typed : '$typed.$ext';
    await _run(() => ref.read(documentsProvider.notifier).rename(widget.record, name));
  }

  /// Opens the system share sheet. Saving from there is how a copy leaves DocNest.
  Future<void> _share() => runSafely(
        context,
        () => shareDocument(ref.read(documentStoreProvider), widget.record),
        message: 'Could not share this document.',
      );

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete this document?'),
        content: const Text('The file will be removed from DocNest. This cannot be undone.'),
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
    if (confirmed != true || !mounted) return;

    try {
      await ref.read(documentsProvider.notifier).remove(widget.record);
    } on Exception {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not delete. Please try again.')),
      );
      return;
    }

    if (!mounted) return;
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.documents);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;
    final record = widget.record;

    return Column(
      children: [
        Expanded(
          flex: 3,
          child: FutureBuilder<File>(
            future: _fileFuture,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Center(
                  child: Text('This file could not be opened.'),
                );
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              return DocumentPreview(record: record, file: snapshot.requireData);
            },
          ),
        ),
        Expanded(
          flex: 2,
          child: Container(
            decoration: BoxDecoration(
              color: palette.elevatedSurface,
              border: Border(top: BorderSide(color: palette.border)),
            ),
            child: ListView(
              padding: const EdgeInsets.all(DocNestSpacing.screen),
              children: [
                Text(record.name, style: theme.textTheme.titleLarge),
                const SizedBox(height: DocNestSpacing.m),
                _InfoRow(
                  label: 'Type',
                  value: record.kind == DocumentKind.pdf ? 'PDF' : 'Image',
                ),
                _InfoRow(label: 'File size', value: formatBytes(record.sizeBytes)),
                _InfoRow(label: 'Added', value: formatDate(record.addedAt)),
                DocumentOrganizeSection(record: record),
                const SizedBox(height: DocNestSpacing.m),
                Wrap(
                  spacing: DocNestSpacing.s,
                  runSpacing: DocNestSpacing.s,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _toggleFavorite,
                      icon: Icon(
                        record.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                      ),
                      label: Text(record.isFavorite ? 'Favorited' : 'Add to favorites'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _toggleArchive,
                      icon: Icon(
                        record.isArchived ? Icons.unarchive_outlined : Icons.archive_outlined,
                      ),
                      label: Text(record.isArchived ? 'Unarchive' : 'Archive'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _rename,
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Rename'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _share,
                      icon: const Icon(Icons.share_outlined),
                      label: const Text('Share'),
                    ),
                  ],
                ),
                const SizedBox(height: DocNestSpacing.section),
                OutlinedButton.icon(
                  onPressed: _confirmDelete,
                  icon: Icon(Icons.delete_outline_rounded, color: palette.error),
                  label: Text(
                    'Delete document',
                    style: TextStyle(color: palette.error),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Owns its text controller, so it is disposed only after the dialog is gone.
class _RenameDialog extends StatefulWidget {
  const _RenameDialog({required this.initialName});

  final String initialName;

  @override
  State<_RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends State<_RenameDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialName);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() => Navigator.of(context).pop(_controller.text.trim());

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Rename document'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(onPressed: _submit, child: const Text('Save')),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: theme.textTheme.bodySmall),
          ),
          Expanded(child: Text(value, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
