import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'app_routes.dart';
import '../../features/splash/presentation/splash_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/authentication/presentation/login_screen.dart';
import '../../features/authentication/presentation/register_screen.dart';
import '../../features/authentication/presentation/forgot_password_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/dream_diary/presentation/dream_list_screen.dart';
import '../../features/dream_diary/presentation/add_dream_screen.dart';
import '../../features/dream_diary/presentation/dream_detail_screen.dart';
import '../../features/dream_diary/presentation/edit_dream_screen.dart';
import '../../features/sleep_tracking/presentation/sleep_tracking_screen.dart';
import '../../features/analytics/presentation/analytics_screen.dart';
import '../../features/history/presentation/history_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../shared/widgets/main_shell.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: false,
    routes: [
      // 1. Splash Screen
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),

      // 2. Onboarding Screen
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),

      // 3. Authentication Screens
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),

      // 4. Main Stateful Shell với 5 Tabs Bottom Navigation
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShell(navigationShell: navigationShell);
        },
        branches: [
          // Branch 0: Trang chủ
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),

          // Branch 1: Giấc mơ
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.dreamDiary,
                builder: (context, state) => const DreamListScreen(),
              ),
            ],
          ),

          // Branch 2: Giấc ngủ (Theo dõi ngủ)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.sleepTracking,
                builder: (context, state) => const SleepTrackingScreen(),
              ),
            ],
          ),

          // Branch 3: Phân tích
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.analytics,
                builder: (context, state) => const AnalyticsScreen(),
              ),
            ],
          ),

          // Branch 4: Cá nhân
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),

      // 5. Các màn hình con (đẩy đè lên toàn màn hình)
      GoRoute(
        path: AppRoutes.addDream,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AddDreamScreen(),
      ),
      GoRoute(
        path: '${AppRoutes.dreamDetail}/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return DreamDetailScreen(dreamId: id);
        },
      ),
      GoRoute(
        path: '${AppRoutes.editDream}/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return EditDreamScreen(dreamId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.history,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const HistoryScreen(),
      ),
    ],
  );
}
