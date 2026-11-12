import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_theme.dart';
import '../../../shared/formatters/formatters.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../documents/application/documents_controller.dart';
import '../application/pdf_builder.dart';
import '../application/scan_session.dart';
import '../data/scan_page.dart';

/// Scanned pages in order. Rotate, retake, delete or drag to reorder, then save
/// everything as one PDF in the documents list.
class ScanReviewScreen extends ConsumerStatefulWidget {
  const ScanReviewScreen({super.key});

  @override
  ConsumerState<ScanReviewScreen> createState() => _ScanReviewScreenState();
}

class _ScanReviewScreenState extends ConsumerState<ScanReviewScreen> {
  late final TextEditingController _nameController =
      TextEditingController(text: _defaultName());
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  static String _defaultName() {
    final now = DateTime.now();
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    return 'Scan ${formatDate(now)} $hour.$minute';
  }

  Future<void> _save() async {
    final pages = ref.read(scanSessionProvider);
    if (pages.isEmpty || _saving) return;
    setState(() => _saving = true);

    final typed = _nameController.text.trim();
    final name = typed.isEmpty ? _defaultName() : typed;
    try {
      final bytes = await buildScanPdf(pages);
      await ref.read(documentsProvider.notifier).saveScannedPdf(bytes: bytes, name: name);
    } on Exception {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save the PDF. Please try again.')),
        );
      }
      return;
    }

    ref.read(scanSessionProvider.notifier).clear();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Saved "$name"')),
    );
    context.go(AppRoutes.documents);
  }

  Future<void> _discardAll() async {
    final count = ref.read(scanSessionProvider).length;
    final discard = await confirmDiscardScan(context, count);
    if (!discard || !mounted) return;
    ref.read(scanSessionProvider.notifier).clear();
    context.go(AppRoutes.documents);
  }

  @override
  Widget build(BuildContext context) {
    final pages = ref.watch(scanSessionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review scan'),
        actions: [
          if (pages.isNotEmpty)
            IconButton(
              tooltip: 'Discard all pages',
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: _discardAll,
            ),
        ],
      ),
      body: pages.isEmpty
          ? const EmptyState(
              icon: Icons.document_scanner_outlined,
              title: 'No pages',
              message: 'Go back and take a photo.',
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    DocNestSpacing.screen,
                    DocNestSpacing.s,
                    DocNestSpacing.screen,
                    0,
                  ),
                  child: TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'File name',
                      suffixText: '.pdf',
                    ),
                    textInputAction: TextInputAction.done,
                  ),
                ),
                Expanded(
                  child: ReorderableListView.builder(
                    padding: const EdgeInsets.fromLTRB(
                      DocNestSpacing.screen,
                      DocNestSpacing.s,
                      DocNestSpacing.screen,
                      DocNestSpacing.s,
                    ),
                    itemCount: pages.length,
                    onReorder: (oldIndex, newIndex) =>
                        ref.read(scanSessionProvider.notifier).reorder(oldIndex, newIndex),
                    itemBuilder: (context, index) {
                      final page = pages[index];
                      return _PageTile(
                        key: ValueKey(page.id),
                        index: index,
                        page: page,
                        dragHandle: ReorderableDragStartListener(
                          index: index,
                          child: const Padding(
                            padding: EdgeInsets.all(12),
                            child: Icon(Icons.drag_handle_rounded),
                          ),
                        ),
                        onRotate: () =>
                            ref.read(scanSessionProvider.notifier).rotatePage(page.id),
                        onRetake: () => context.push(AppRoutes.scanRetake(page.id)),
                        onDelete: () =>
                            ref.read(scanSessionProvider.notifier).removePage(page.id),
                      );
                    },
                  ),
                ),
              ],
            ),
      bottomNavigationBar: pages.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  DocNestSpacing.screen,
                  DocNestSpacing.xs,
                  DocNestSpacing.screen,
                  DocNestSpacing.s,
                ),
                child: FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.picture_as_pdf_rounded),
                  label: Text(_saving ? 'Saving...' : 'Save as PDF'),
                ),
              ),
            ),
    );
  }
}

class _PageTile extends StatelessWidget {
  const _PageTile({
    super.key,
    required this.index,
    required this.page,
    required this.dragHandle,
    required this.onRotate,
    required this.onRetake,
    required this.onDelete,
  });

  final int index;
  final ScanPage page;
  final Widget dragHandle;
  final VoidCallback onRotate;
  final VoidCallback onRetake;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;
    final degrees = page.quarterTurns * 90;

    return Container(
      margin: const EdgeInsets.only(bottom: DocNestSpacing.s),
      padding: const EdgeInsets.all(DocNestSpacing.s),
      decoration: BoxDecoration(
        color: palette.elevatedSurface,
        borderRadius: BorderRadius.circular(DocNestSpacing.radiusCard),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 64,
              height: 84,
              child: ColoredBox(
                color: DocNestColors.darkBackground,
                // Rotation is shown here and applied to the PDF at save time.
                child: RotatedBox(
                  quarterTurns: page.quarterTurns,
                  child: Image.file(
                    File(page.path),
                    fit: BoxFit.contain,
                    cacheWidth: 200,
                    errorBuilder: (context, error, stackTrace) => Icon(
                      Icons.broken_image_outlined,
                      color: DocNestColors.darkTextSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: DocNestSpacing.s),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Page ${index + 1}', style: theme.textTheme.titleMedium),
                Text(
                  degrees == 0 ? 'Not rotated' : 'Rotated $degrees°',
                  style: theme.textTheme.labelMedium,
                ),
                Row(
                  children: [
                    IconButton(
                      tooltip: 'Rotate 90°',
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.rotate_right_rounded),
                      onPressed: onRotate,
                    ),
                    IconButton(
                      tooltip: 'Retake',
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.camera_alt_outlined),
                      onPressed: onRetake,
                    ),
                    IconButton(
                      tooltip: 'Delete page',
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.delete_outline_rounded),
                      onPressed: onDelete,
                    ),
                  ],
                ),
              ],
            ),
          ),
          dragHandle,
        ],
      ),
    );
  }
}

/// Asks before throwing away scanned pages. Returns true when the user confirms.
Future<bool> confirmDiscardScan(BuildContext context, int pageCount) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text('Discard $pageCount ${pageCount == 1 ? 'page' : 'pages'}?'),
      content: const Text('The scanned pages will be removed. This cannot be undone.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Keep'),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text('Discard', style: TextStyle(color: context.palette.error)),
        ),
      ],
    ),
  );
  return confirmed == true;
}
