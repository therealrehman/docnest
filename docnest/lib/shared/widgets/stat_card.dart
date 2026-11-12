import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';

import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_theme.dart';

/// Statistics card: supporting icon, large number, small label.
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.value,
    required this.label,
    required this.icon,
    required this.accent,
  });

  final String value;
  final String label;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;

    return Container(
      padding: const EdgeInsets.all(DocNestSpacing.m),
      decoration: BoxDecoration(
        color: palette.elevatedSurface,
        borderRadius: BorderRadius.circular(DocNestSpacing.radiusCard),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: accent),
          const SizedBox(height: DocNestSpacing.s),
          Text(
            value,
            style: theme.textTheme.headlineLarge?.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: DocNestSpacing.xxs),
          Text(label, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}
