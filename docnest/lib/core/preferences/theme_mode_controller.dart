import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Holds the Light / Dark / System choice and remembers it between launches.
class ThemeModeController extends Notifier<ThemeMode> {
  static const _key = 'theme_mode_v1';

  @override
  ThemeMode build() {
    _restore();
    return ThemeMode.system;
  }

  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_key);
      final mode = saved == null ? null : ThemeMode.values.asNameMap()[saved];
      if (mode != null) state = mode;
    } on Exception {
      // Storage unavailable: keep the system default.
    }
  }

  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, mode.name);
    } on Exception {
      // The choice still applies for this session.
    }
  }
}

final themeModeProvider = NotifierProvider<ThemeModeController, ThemeMode>(
  ThemeModeController.new,
);
