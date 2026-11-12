/// All route paths live here so screens never hardcode strings.
class AppRoutes {
  AppRoutes._();

  static const splash = '/splash';
  static const onboarding = '/onboarding';
  static const home = '/home';
  static const documents = '/documents';
  static const reminders = '/reminders';
  static const settings = '/settings';

  /// Full-screen scan flow. Outside the shell, so the bottom bar is hidden.
  static const scan = '/scan';
  static const scanReview = '/scan/review';

  /// Scan screen in retake mode: the next photo replaces [pageId].
  static String scanRetake(String pageId) => '/scan?replace=$pageId';

  /// Route pattern for GoRouter.
  static const documentDetailsPattern = '/documents/:docId';

  /// Concrete path for one document.
  static String documentDetails(String id) => '/documents/$id';

  /// Categories and folders list. Outside the shell, like the other detail pages.
  static const folders = '/folders';

  /// Route pattern for one folder's documents.
  static const folderDetailsPattern = '/folders/:folderId';

  /// Concrete path for one folder.
  static String folderDetails(String id) => '/folders/$id';

  /// Personal filing rules, opened from Settings. Outside the shell, like the other detail pages.
  static const filingRules = '/filing-rules';
}
