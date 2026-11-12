import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Remembers whether onboarding was finished. Stores one non-sensitive flag only.
class OnboardingStore {
  static const _completedKey = 'onboarding_completed_v1';

  Future<bool> isCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_completedKey) ?? false;
    } on Exception {
      return false;
    }
  }

  Future<void> markCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_completedKey, true);
    } on Exception {
      // Non-critical: onboarding simply shows again on the next launch.
    }
  }
}

final onboardingStoreProvider = Provider<OnboardingStore>((ref) => OnboardingStore());
