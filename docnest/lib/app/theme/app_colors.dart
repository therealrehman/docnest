import 'package:flutter/material.dart';

/// Exact design tokens from the DocNest blueprint (section 3).
class DocNestColors {
  DocNestColors._();

  static const primaryBlue = Color(0xFF0879E8);

  // Dark theme
  static const darkBackground = Color(0xFF081B32);
  static const darkSurface = Color(0xFF102938);
  static const darkElevated = Color(0xFF173B55);
  static const darkBorder = Color(0xFF263E56);
  static const darkTextPrimary = Color(0xFFFFFFFF);
  static const darkTextSecondary = Color(0xFFA9B9CC);
  static const darkTextMuted = Color(0xFF74879D);

  // Light theme
  static const lightBackground = Color(0xFFF5F8FC);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightSecondarySurface = Color(0xFFEEF4FA);
  static const lightBorder = Color(0xFFD9E4EF);
  static const lightTextPrimary = Color(0xFF17283D);
  static const lightTextSecondary = Color(0xFF61748A);
}

/// Semantic colours that differ between dark and light themes
/// (cyan accent, success, warning, error, borders and surfaces).
@immutable
class DocNestPalette extends ThemeExtension<DocNestPalette> {
  const DocNestPalette({
    required this.accentCyan,
    required this.success,
    required this.warning,
    required this.error,
    required this.border,
    required this.elevatedSurface,
    required this.secondarySurface,
    required this.textSecondary,
    required this.textMuted,
  });

  static const dark = DocNestPalette(
    accentCyan: Color(0xFF22C5E8),
    success: Color(0xFF16B8A6),
    warning: Color(0xFFF2A93B),
    error: Color(0xFFE65353),
    border: DocNestColors.darkBorder,
    elevatedSurface: DocNestColors.darkElevated,
    secondarySurface: DocNestColors.darkSurface,
    textSecondary: DocNestColors.darkTextSecondary,
    textMuted: DocNestColors.darkTextMuted,
  );

  static const light = DocNestPalette(
    accentCyan: Color(0xFF16B8D8),
    success: Color(0xFF16A36A),
    warning: Color(0xFFD98B19),
    error: Color(0xFFD94747),
    border: DocNestColors.lightBorder,
    elevatedSurface: DocNestColors.lightSurface,
    secondarySurface: DocNestColors.lightSecondarySurface,
    textSecondary: DocNestColors.lightTextSecondary,
    // Blueprint does not define a light-theme muted token; secondary text is used instead.
    textMuted: DocNestColors.lightTextSecondary,
  );

  final Color accentCyan;
  final Color success;
  final Color warning;
  final Color error;
  final Color border;
  final Color elevatedSurface;
  final Color secondarySurface;
  final Color textSecondary;
  final Color textMuted;

  @override
  DocNestPalette copyWith({
    Color? accentCyan,
    Color? success,
    Color? warning,
    Color? error,
    Color? border,
    Color? elevatedSurface,
    Color? secondarySurface,
    Color? textSecondary,
    Color? textMuted,
  }) {
    return DocNestPalette(
      accentCyan: accentCyan ?? this.accentCyan,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      error: error ?? this.error,
      border: border ?? this.border,
      elevatedSurface: elevatedSurface ?? this.elevatedSurface,
      secondarySurface: secondarySurface ?? this.secondarySurface,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
    );
  }

  @override
  ThemeExtension<DocNestPalette> lerp(ThemeExtension<DocNestPalette>? other, double t) {
    if (other is! DocNestPalette) return this;
    return DocNestPalette(
      accentCyan: Color.lerp(accentCyan, other.accentCyan, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      error: Color.lerp(error, other.error, t)!,
      border: Color.lerp(border, other.border, t)!,
      elevatedSurface: Color.lerp(elevatedSurface, other.elevatedSurface, t)!,
      secondarySurface: Color.lerp(secondarySurface, other.secondarySurface, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
    );
  }
}
