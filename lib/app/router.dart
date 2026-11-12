import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/documents/documents_screen.dart';
import '../features/documents/presentation/document_details_screen.dart';
import '../features/home/home_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/reminders/reminders_screen.dart';
import '../features/settings/filing_rules_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/folders/presentation/folder_detail_screen.dart';
import '../features/folders/presentation/folders_screen.dart';
import '../features/scan/presentation/scan_review.dart';
import '../features/scan/presentation/scan_screen.dart';
import '../features/splash/splash_screen.dart';
import 'motion/motion_tokens.dart';
import 'routes.dart';
import 'shell/app_shell.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    routes: [
      _fadeRoute(AppRoutes.splash, (_) => const SplashScreen()),
      _fadeRoute(AppRoutes.onboarding, (_) => const OnboardingScreen()),
      // Scan flow: outside the shell, like the detail page.
      _fadeRoute(
        AppRoutes.scan,
        (state) => ScanScreen(replacePageId: state.uri.queryParameters['replace']),
      ),
      _fadeRoute(AppRoutes.scanReview, (_) => const ScanReviewScreen()),
      _fadeRoute(AppRoutes.folders, (_) => const FoldersScreen()),
      _fadeRoute(
        AppRoutes.folderDetailsPattern,
        (state) => FolderDetailScreen(folderId: state.pathParameters['folderId'] ?? ''),
      ),
      _fadeRoute(AppRoutes.filingRules, (_) => const FilingRulesScreen()),
      // Full-screen detail page: outside the shell, so the bottom bar is hidden.
      _fadeRoute(
        AppRoutes.documentDetailsPattern,
        (state) => DocumentDetailsScreen(
          documentId: state.pathParameters['docId'] ?? '',
        ),
      ),
      ShellRoute(
        builder: (context, state, child) =>
            AppShell(location: state.uri.path, child: child),
        routes: [
          _fadeRoute(AppRoutes.home, (_) => const HomeScreen()),
          _fadeRoute(AppRoutes.documents, (_) => const DocumentsScreen()),
          _fadeRoute(AppRoutes.reminders, (_) => const RemindersScreen()),
          _fadeRoute(AppRoutes.settings, (_) => const SettingsScreen()),
        ],
      ),
    ],
  );
});

GoRoute _fadeRoute(String path, Widget Function(GoRouterState state) builder) {
  return GoRoute(
    path: path,
    pageBuilder: (context, state) => CustomTransitionPage<void>(
      key: state.pageKey,
      child: builder(state),
      transitionDuration: MotionTokens.pageTransition,
      reverseTransitionDuration: MotionTokens.pageTransition,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: MotionTokens.screen),
          child: child,
        );
      },
    ),
  );
}
