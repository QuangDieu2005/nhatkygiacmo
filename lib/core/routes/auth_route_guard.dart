import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import 'app_routes.dart';

typedef OnboardingStatusReader = Future<bool> Function();

class AuthRouteGuard {
  AuthRouteGuard({
    required this.authProvider,
    OnboardingStatusReader? onboardingStatusReader,
  }) : _onboardingStatusReader =
           onboardingStatusReader ?? _readOnboardingStatus;

  final AuthProvider authProvider;
  final OnboardingStatusReader _onboardingStatusReader;

  Future<String?> redirect(Uri location) async {
    final path = location.path;
    final requestedLocation = _requestedLocation(location);

    if (!authProvider.isInitialized) {
      if (path == AppRoutes.splash) return null;
      return _withReturnLocation(AppRoutes.splash, requestedLocation);
    }

    final onboardingCompleted = await _onboardingStatusReader();
    if (!onboardingCompleted) {
      if (path == AppRoutes.onboarding) return null;
      return _withReturnLocation(AppRoutes.onboarding, requestedLocation);
    }

    if (authProvider.isAuthenticated) {
      if (_isPublicEntry(path)) {
        return AppRoutes.protectedReturnLocation(
              location.queryParameters['from'],
            ) ??
            AppRoutes.home;
      }
      return null;
    }

    if (path == AppRoutes.onboarding) return AppRoutes.login;
    if (_isAuthRoute(path)) return null;

    if (AppRoutes.isProtectedLocation(location)) {
      return _withReturnLocation(AppRoutes.login, requestedLocation);
    }
    if (path == AppRoutes.splash) return AppRoutes.login;
    return AppRoutes.login;
  }

  static Future<bool> _readOnboardingStatus() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      return preferences.getBool(AppConstants.prefOnboardingCompleted) ?? false;
    } catch (_) {
      return false;
    }
  }

  static String _requestedLocation(Uri location) {
    if (location.path == AppRoutes.splash ||
        location.path == AppRoutes.onboarding) {
      final requested = location.queryParameters['from'];
      if (requested != null &&
          requested.startsWith('/') &&
          !requested.startsWith('//')) {
        return requested;
      }
    }
    return location.toString();
  }

  static bool _isAuthRoute(String path) =>
      path == AppRoutes.login ||
      path == AppRoutes.register ||
      path == AppRoutes.forgotPassword;

  static bool _isPublicEntry(String path) =>
      path == AppRoutes.splash ||
      path == AppRoutes.onboarding ||
      _isAuthRoute(path);

  static String _withReturnLocation(String route, String requestedLocation) =>
      '$route?from=${Uri.encodeQueryComponent(requestedLocation)}';
}
