import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/constants/default_categories.dart';
import '../data/folder_record.dart';

/// Icon for a folder. Built-in folders use their category icon.
IconData folderIconFor(FolderRecord folder) {
  if (folder.isBuiltIn) {
    for (final category in defaultCategories) {
      if (category.name == folder.name) return category.icon;
    }
  }
  return Icons.folder_outlined;
}

/// Folder row: icon, name, document count and chevron. Same look as DocumentTile.
class FolderTile extends StatelessWidget {
  const FolderTile({
    super.key,
    required this.folder,
    required this.count,
    required this.onTap,
  });

  final FolderRecord folder;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;
    final radius = BorderRadius.circular(DocNestSpacing.radiusCard);

    return Material(
      color: palette.elevatedSurface,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 76),
          padding: const EdgeInsets.all(DocNestSpacing.s),
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: palette.border),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: DocNestColors.primaryBlue.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(folderIconFor(folder), color: DocNestColors.primaryBlue),
              ),
              const SizedBox(width: DocNestSpacing.s),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      folder.name,
                      style: theme.textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: DocNestSpacing.xxs),
                    Text(
                      count == 1 ? '1 document' : '$count documents',
                      style: theme.textTheme.labelMedium,
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: palette.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
