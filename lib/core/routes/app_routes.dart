class AppRoutes {
  AppRoutes._();

  static const String splash = '/splash';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';

  // 5 Tab chính trong Shell
  static const String home = '/home';
  static const String dreamDiary = '/dream-diary';
  static const String sleepTracking = '/sleep-tracking';
  static const String analytics = '/analytics';
  static const String profile = '/profile';

  // Chi tiết & Thao tác phụ
  static const String addDream = '/add-dream';
  static const String dreamDetail = '/dream-detail'; // /dream-detail/:id
  static const String editDream = '/edit-dream'; // /edit-dream/:id
  static const String history = '/history';

  static bool isProtectedLocation(Uri location) {
    final path = location.path;
    return path == home ||
        path == dreamDiary ||
        path == sleepTracking ||
        path == analytics ||
        path == profile ||
        path == history ||
        path == addDream ||
        path.startsWith('$dreamDetail/') ||
        path.startsWith('$editDream/');
  }

  static String? protectedReturnLocation(String? value) {
    if (value == null || value.isEmpty || value.startsWith('//')) return null;
    final uri = Uri.tryParse(value);
    if (uri == null ||
        uri.hasScheme ||
        uri.hasAuthority ||
        !uri.hasAbsolutePath) {
      return null;
    }
    return isProtectedLocation(uri) ? uri.toString() : null;
  }

  static String locationAfterOnboarding(String? value) {
    final protected = protectedReturnLocation(value);
    if (protected != null) {
      return '$login?from=${Uri.encodeQueryComponent(protected)}';
    }
    if (value == login || value == register || value == forgotPassword) {
      return value!;
    }
    return login;
  }

  static String locationAfterLogin(String? value) =>
      protectedReturnLocation(value) ?? home;
}
