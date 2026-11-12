import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/motion/motion_tokens.dart';
import '../../app/routes.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_theme.dart';
import '../../core/preferences/onboarding_store.dart';
import '../../shared/widgets/docnest_logo.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  // Animation length plus a short hold keeps the total inside the 1.2–1.8s target.
  static const _animationLength = Duration(milliseconds: 1400);
  static const _holdAfterAnimation = Duration(milliseconds: 250);

  late final AnimationController _controller;
  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;
  late final Animation<double> _cyanRing;
  late final Animation<double> _nameFade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _animationLength);

    final logoEnd = MotionTokens.splashLogo.inMilliseconds / _animationLength.inMilliseconds;
    final logoCurve = Interval(0, logoEnd, curve: MotionTokens.entrance);

    _logoFade = CurvedAnimation(parent: _controller, curve: logoCurve);
    _logoScale = Tween<double>(begin: 0.92, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: logoCurve),
    );
    // One-time cyan highlight: fades in and back out.
    _cyanRing = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0, end: 0.6), weight: 1),
      TweenSequenceItem(tween: Tween<double>(begin: 0.6, end: 0), weight: 1),
    ]).animate(CurvedAnimation(parent: _controller, curve: const Interval(0.3, 0.8)));
    _nameFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.45, 0.85, curve: Curves.easeOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  Future<void> _run() async {
    if (!mounted) return;
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion) {
      _controller.value = 1;
    } else {
      await _controller.forward();
    }

    await Future<void>.delayed(_holdAfterAnimation);
    if (!mounted) return;

    final completed = await ref.read(onboardingStoreProvider).isCompleted();
    if (!mounted) return;
    context.go(completed ? AppRoutes.home : AppRoutes.onboarding);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FadeTransition(
              opacity: _logoFade,
              child: ScaleTransition(
                scale: _logoScale,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    FadeTransition(
                      opacity: _cyanRing,
                      child: Container(
                        width: 136,
                        height: 136,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: palette.accentCyan, width: 2),
                        ),
                      ),
                    ),
                    const DocNestLogo(size: 112),
                  ],
                ),
              ),
            ),
            const SizedBox(height: DocNestSpacing.section),
            FadeTransition(
              opacity: _nameFade,
              child: Column(
                children: [
                  Text('DocNest', style: theme.textTheme.headlineLarge),
                  const SizedBox(height: DocNestSpacing.xxs),
                  Text(
                    'Your Personal Document Life Manager',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
