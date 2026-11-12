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
  static const String editDream = '/edit-dream';     // /edit-dream/:id
  static const String history = '/history';
}
