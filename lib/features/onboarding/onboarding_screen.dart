import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/motion/motion_tokens.dart';
import '../../app/routes.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_theme.dart';
import '../../core/preferences/onboarding_store.dart';
import '../../shared/widgets/primary_button.dart';
import 'onboarding_illustration.dart';

class _OnboardingPage {
  const _OnboardingPage({required this.heading, required this.description});

  final String heading;
  final String description;
}

const _pages = <_OnboardingPage>[
  _OnboardingPage(
    heading: 'All Your Documents in One Place',
    description: 'Keep important personal documents organized and easy to find.',
  ),
  _OnboardingPage(
    heading: 'Never Miss Important Dates',
    description: 'Track expiry dates, warranty periods and bill deadlines with smart reminders.',
  ),
  _OnboardingPage(
    heading: 'Your Privacy Comes First',
    description: 'Protect your important documents with local storage and security features.',
  ),
];

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _index = 0;

  bool get _isLast => _index == _pages.length - 1;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToPage(int page) {
    final duration = MotionTokens.resolve(context, MotionTokens.onboardingSlide);
    if (duration == Duration.zero) {
      _pageController.jumpToPage(page);
    } else {
      _pageController.animateToPage(page, duration: duration, curve: MotionTokens.entrance);
    }
  }

  Future<void> _finish() async {
    await ref.read(onboardingStoreProvider).markCompleted();
    if (!mounted) return;
    context.go(AppRoutes.home);
  }

  void _onPrimaryPressed() {
    if (_isLast) {
      _finish();
    } else {
      _goToPage(_index + 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: DocNestSpacing.screen),
          child: Column(
            children: [
              SizedBox(
                height: 48,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: _isLast
                      ? const SizedBox.shrink()
                      : TextButton(onPressed: _finish, child: const Text('Skip')),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _pages.length,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemBuilder: (context, i) {
                    final page = _pages[i];
                    return Column(
                      children: [
                        Expanded(
                          flex: 45,
                          child: Center(child: OnboardingIllustration(page: i)),
                        ),
                        Expanded(
                          flex: 55,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(page.heading, style: theme.textTheme.headlineMedium),
                              const SizedBox(height: DocNestSpacing.s),
                              Text(
                                page.description,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: palette.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < _pages.length; i++)
                    AnimatedContainer(
                      duration: MotionTokens.resolve(context, MotionTokens.smallFade),
                      curve: MotionTokens.entrance,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: i == _index ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: i == _index ? DocNestColors.primaryBlue : palette.border,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: DocNestSpacing.section),
              PrimaryButton(
                label: _isLast ? 'Get Started' : 'Next',
                onPressed: _onPrimaryPressed,
              ),
              const SizedBox(height: DocNestSpacing.section),
            ],
          ),
        ),
      ),
    );
  }
}
