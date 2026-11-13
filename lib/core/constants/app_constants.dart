class AppConstants {
  AppConstants._();

  static const String appName = 'Dream Diary';
  static const String appTagline = 'Nhật ký giấc mơ và theo dõi giấc ngủ';
  static const String appVersion = '1.0.0';

  // Cấu hình ngủ mặc định
  static const int defaultSleepGoalHours = 8;
  static const int minSleepGoalHours = 5;
  static const int maxSleepGoalHours = 12;

  // Validation
  static const int maxDreamTitleLength = 100;
  static const int maxDreamContentLength = 2000;

  // Key SharedPreferences
  static const String prefOnboardingCompleted = 'pref_onboarding_completed';
  static const String prefIsLoggedIn = 'pref_is_logged_in';
  static const String prefUser = 'pref_user_data';
  // Legacy mock token key. AuthService removes this during migration to secure storage.
  static const String prefAuthToken = 'pref_auth_token';
  static const String prefSleepGoal = 'pref_sleep_goal';
  static const String prefActiveSession = 'pref_active_sleep_session';
  static const String prefPendingCompletedSession =
      'pref_pending_completed_sleep_session';
  static const String pendingSleepSnapshotField = 'snapshot';
  static const String pendingSleepRepositorySavedField = 'repository_saved';

  // Public API endpoint configuration.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000/api',
  );
}
