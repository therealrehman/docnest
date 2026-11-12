import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';

class AppTheme {
  AppTheme._();

  static ThemeData dark() => _build(
        brightness: Brightness.dark,
        background: DocNestColors.darkBackground,
        surface: DocNestColors.darkSurface,
        textPrimary: DocNestColors.darkTextPrimary,
        textSecondary: DocNestColors.darkTextSecondary,
        palette: DocNestPalette.dark,
      );

  static ThemeData light() => _build(
        brightness: Brightness.light,
        background: DocNestColors.lightBackground,
        surface: DocNestColors.lightSurface,
        textPrimary: DocNestColors.lightTextPrimary,
        textSecondary: DocNestColors.lightTextSecondary,
        palette: DocNestPalette.light,
      );

  static ThemeData _build({
    required Brightness brightness,
    required Color background,
    required Color surface,
    required Color textPrimary,
    required Color textSecondary,
    required DocNestPalette palette,
  }) {
    final scheme = ColorScheme.fromSeed(
      seedColor: DocNestColors.primaryBlue,
      brightness: brightness,
    ).copyWith(
      primary: DocNestColors.primaryBlue,
      onPrimary: Colors.white,
      secondary: palette.accentCyan,
      surface: surface,
      onSurface: textPrimary,
      error: palette.error,
      outline: palette.border,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      textTheme: _textTheme(textPrimary, textSecondary),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(DocNestSpacing.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DocNestSpacing.radiusButton),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      extensions: [palette],
    );
  }

  /// Type scale from blueprint section 4. Inter is the target font;
  /// it is not bundled yet, so the platform default is used for now.
  static TextTheme _textTheme(Color primary, Color secondary) {
    return TextTheme(
      headlineLarge: TextStyle(fontSize: 30, fontWeight: FontWeight.w700, height: 1.2, color: primary),
      headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, height: 1.25, color: primary),
      titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, height: 1.3, color: primary),
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, height: 1.35, color: primary),
      bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, height: 1.45, color: primary),
      bodySmall: TextStyle(fontSize: 13, fontWeight: FontWeight.w400, height: 1.4, color: secondary),
      labelLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: primary),
      labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: secondary),
      labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w400, color: secondary),
    );
  }
}

/// Shortcut for the semantic palette: `context.palette.success`.
extension DocNestThemeX on BuildContext {
  DocNestPalette get palette =>
      Theme.of(this).extension<DocNestPalette>() ?? DocNestPalette.dark;
}
