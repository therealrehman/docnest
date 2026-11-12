import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/motion/motion_tokens.dart';
import '../../app/routes.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_theme.dart';
import '../../core/constants/default_categories.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/entrance_fade.dart';
import '../../shared/widgets/stat_card.dart';
import '../documents/application/documents_controller.dart';
import '../documents/application/import_flow.dart';
import '../documents/data/document_record.dart';
import '../documents/presentation/document_tile.dart';

/// Home dashboard. Document count and recent documents are real.
/// Import and scan work in Phase 2. Other actions stay disabled until their phase.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docs = ref.watch(documentsProvider);
    final total = docs.valueOrNull?.where((d) => !d.isArchived).length ?? 0;
    final featured = defaultCategories
        .where((c) => homeFeaturedCategoryNames.contains(c.name))
        .toList();

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add',
        onPressed: () => _showAddSheet(context, ref),
        child: const Icon(Icons.add_rounded),
      ),
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            DocNestSpacing.screen,
            DocNestSpacing.m,
            DocNestSpacing.screen,
            96,
          ),
          children: [
            const EntranceFade(child: _Header()),
            const SizedBox(height: DocNestSpacing.section),
            EntranceFade(child: _StatsRow(totalDocuments: total)),
            const SizedBox(height: DocNestSpacing.section),
            const _SectionTitle(title: 'Quick actions', trailing: 'Some coming soon'),
            const SizedBox(height: DocNestSpacing.s),
            const _QuickActionsRow(),
            const SizedBox(height: DocNestSpacing.section),
            EntranceFade(
              delay: MotionTokens.listStagger * 4,
              child: const _SectionTitle(title: 'Categories'),
            ),
            const SizedBox(height: DocNestSpacing.s),
            EntranceFade(
              delay: MotionTokens.listStagger * 4,
              child: _CategoryGrid(
                categories: featured,
                documents: docs.valueOrNull ?? const <DocumentRecord>[],
              ),
            ),
            const SizedBox(height: DocNestSpacing.section),
            EntranceFade(
              delay: MotionTokens.listStagger * 6,
              child: const _SectionTitle(title: 'Recent documents'),
            ),
            const SizedBox(height: DocNestSpacing.s),
            EntranceFade(
              delay: const Duration(milliseconds: 170),
              child: _RecentDocuments(docs: docs),
            ),
          ],
        ),
      ),
    );
  }
}

void _showAddSheet(BuildContext context, WidgetRef ref) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.file_upload_outlined),
            title: const Text('Import document'),
            subtitle: const Text('PDF or image from your phone'),
            onTap: () {
              Navigator.of(sheetContext).pop();
              runImport(context, ref);
            },
          ),
          ListTile(
            leading: const Icon(Icons.document_scanner_outlined),
            title: const Text('Scan document'),
            subtitle: const Text('Take photos and save them as one PDF'),
            onTap: () {
              Navigator.of(sheetContext).pop();
              context.push(AppRoutes.scan);
            },
          ),
          const ListTile(
            enabled: false,
            leading: Icon(Icons.create_new_folder_outlined),
            title: Text('Create folder'),
            subtitle: Text('Coming soon'),
          ),
          const SizedBox(height: DocNestSpacing.s),
        ],
      ),
    ),
  );
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hello!',
                style: theme.textTheme.headlineMedium?.copyWith(fontSize: 22),
              ),
              Text(
                'Everything you add stays on this phone.',
                style: theme.textTheme.bodySmall?.copyWith(color: palette.textSecondary),
              ),
            ],
          ),
        ),
        const IconButton(
          tooltip: 'Notifications arrive with reminders',
          onPressed: null,
          icon: Icon(Icons.notifications_none_rounded),
        ),
      ],
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.totalDocuments});

  final int totalDocuments;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Row(
      children: [
        Expanded(
          child: StatCard(
            value: '$totalDocuments',
            label: 'Total documents',
            icon: Icons.folder_rounded,
            accent: DocNestColors.primaryBlue,
          ),
        ),
        const SizedBox(width: DocNestSpacing.s),
        Expanded(
          child: StatCard(
            value: '0',
            label: 'Upcoming reminders',
            icon: Icons.schedule_rounded,
            accent: palette.warning,
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.trailing});

  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(child: Text(title, style: theme.textTheme.titleLarge)),
        if (trailing != null) Text(trailing!, style: theme.textTheme.labelMedium),
      ],
    );
  }
}

class _QuickActionsRow extends ConsumerWidget {
  const _QuickActionsRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final tiles = <(IconData, String, Color, VoidCallback?)>[
      (Icons.file_upload_outlined, 'Import', DocNestColors.primaryBlue, () => runImport(context, ref)),
      (Icons.document_scanner_outlined, 'Scan', palette.accentCyan, () => context.push(AppRoutes.scan)),
      (Icons.create_new_folder_outlined, 'Folder', DocNestColors.primaryBlue, null),
      (Icons.alarm_add_outlined, 'Reminder', palette.warning, null),
    ];

    return Row(
      children: [
        for (var i = 0; i < tiles.length; i++) ...[
          if (i > 0) const SizedBox(width: DocNestSpacing.s),
          Expanded(
            child: EntranceFade(
              delay: MotionTokens.listStagger * i,
              child: _QuickActionTile(
                icon: tiles[i].$1,
                label: tiles[i].$2,
                color: tiles[i].$3,
                onTap: tiles[i].$4,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = BorderRadius.circular(DocNestSpacing.radiusCard);

    final content = Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: radius,
      ),
      child: Column(
        children: [
          Icon(icon, size: 28, color: color),
          const SizedBox(height: DocNestSpacing.xs),
          Text(label, style: theme.textTheme.bodySmall),
        ],
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(borderRadius: radius, onTap: onTap, child: content),
      );
    }

    return Tooltip(
      message: 'Coming soon',
      child: Opacity(opacity: 0.6, child: content),
    );
  }
}

class _RecentDocuments extends StatelessWidget {
  const _RecentDocuments({required this.docs});

  final AsyncValue<List<DocumentRecord>> docs;

  @override
  Widget build(BuildContext context) {
    if (docs.isLoading && !docs.hasValue) {
      return const Padding(
        padding: EdgeInsets.all(DocNestSpacing.section),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (docs.hasError && !docs.hasValue) {
      return const EmptyState(
        icon: Icons.error_outline_rounded,
        title: 'Could not load documents',
        message: 'Open the Documents tab to try again.',
      );
    }

    final items = (docs.valueOrNull ?? const <DocumentRecord>[])
        .where((d) => !d.isArchived)
        .toList();
    if (items.isEmpty) {
      return const EmptyState(
        icon: Icons.description_outlined,
        title: 'No documents yet',
        message: 'Tap Import to add a PDF or image. Files you add will appear here.',
      );
    }

    return Column(
      children: [
        for (final record in items.take(3))
          Padding(
            padding: const EdgeInsets.only(bottom: DocNestSpacing.xs),
            child: DocumentTile(
              record: record,
              onTap: () => context.push(AppRoutes.documentDetails(record.id)),
            ),
          ),
      ],
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({required this.categories, required this.documents});

  final List<DefaultCategory> categories;
  final List<DocumentRecord> documents;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: DocNestSpacing.s,
      crossAxisSpacing: DocNestSpacing.s,
      childAspectRatio: 2.6,
      children: [
        for (final category in categories)
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(DocNestSpacing.radiusCard),
              onTap: () => context.push(
                AppRoutes.folderDetails(builtInFolderId(category.name)),
              ),
              child: _CategoryCard(
                category: category,
                count: documents
                    .where((d) =>
                        d.folderId == builtInFolderId(category.name) && !d.isArchived)
                    .length,
              ),
            ),
          ),
      ],
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.category, required this.count});

  final DefaultCategory category;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;

    return Container(
      padding: const EdgeInsets.all(DocNestSpacing.s),
      decoration: BoxDecoration(
        color: palette.elevatedSurface,
        borderRadius: BorderRadius.circular(DocNestSpacing.radiusCard),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: DocNestColors.primaryBlue.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(category.icon, size: 20, color: DocNestColors.primaryBlue),
          ),
          const SizedBox(width: DocNestSpacing.s),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  category.name,
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  count == 1 ? '1 document' : '$count documents',
                  style: theme.textTheme.labelMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
