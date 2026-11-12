import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_theme.dart';
import '../../../shared/formatters/formatters.dart';
import '../data/document_record.dart';

/// Document row (blueprint section 7): type icon, name, meta line and chevron.
class DocumentTile extends StatelessWidget {
  const DocumentTile({super.key, required this.record, required this.onTap});

  final DocumentRecord record;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;
    final isPdf = record.kind == DocumentKind.pdf;
    final typeLabel = isPdf ? 'PDF' : 'Image';
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
                child: Icon(
                  isPdf ? Icons.picture_as_pdf_rounded : Icons.image_rounded,
                  color: DocNestColors.primaryBlue,
                ),
              ),
              const SizedBox(width: DocNestSpacing.s),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      record.name,
                      style: theme.textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: DocNestSpacing.xxs),
                    Text(
                      '$typeLabel · ${formatBytes(record.sizeBytes)} · ${formatDate(record.addedAt)}',
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
