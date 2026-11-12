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
  static const String prefAuthToken = 'pref_auth_token';
  static const String prefSleepGoal = 'pref_sleep_goal';
  static const String prefActiveSession = 'pref_active_sleep_session';

  // API & Supabase placeholders
  static const String apiBaseUrl = 'http://localhost:5000/api';
  static const String supabaseUrl = 'https://your-project.supabase.co';
  static const String supabaseAnonKey = 'your-anon-key';
}
