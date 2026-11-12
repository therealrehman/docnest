import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_theme.dart';

/// Placeholder folder-and-shield logo. Final brand artwork comes in the polish phase.
class DocNestLogo extends StatelessWidget {
  const DocNestLogo({super.key, this.size = 96});

  final double size;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            DocNestColors.primaryBlue.withValues(alpha: 0.28),
            DocNestColors.primaryBlue.withValues(alpha: 0),
          ],
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(Icons.folder_rounded, size: size * 0.62, color: DocNestColors.primaryBlue),
          Positioned(
            right: size * 0.12,
            bottom: size * 0.14,
            child: Icon(Icons.shield_rounded, size: size * 0.3, color: palette.accentCyan),
          ),
        ],
      ),
    );
  }
}
