import 'package:flutter/material.dart';

/// Central animation tokens (blueprint section 18).
/// Durations and curves are defined only here, never hardcoded in screens.
class MotionTokens {
  MotionTokens._();

  static const buttonPress = Duration(milliseconds: 100);
  static const smallFade = Duration(milliseconds: 180);
  static const cardAppearance = Duration(milliseconds: 220);
  static const pageTransition = Duration(milliseconds: 280);
  static const bottomSheet = Duration(milliseconds: 260);
  static const cardExpansion = Duration(milliseconds: 220);
  static const successFeedback = Duration(milliseconds: 350);
  static const errorFeedback = Duration(milliseconds: 200);
  static const onboardingSlide = Duration(milliseconds: 280);
  static const splashLogo = Duration(milliseconds: 450);
  static const listStagger = Duration(milliseconds: 25);

  static const entrance = Curves.easeOutCubic;
  static const screen = Curves.easeInOut;
  static const buttonFeedback = Curves.easeOut;
  static const progress = Curves.linear;

  /// Returns [Duration.zero] when the system Reduce Motion (animations off) setting is on.
  static Duration resolve(BuildContext context, Duration duration) {
    final disabled = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return disabled ? Duration.zero : duration;
  }
}
