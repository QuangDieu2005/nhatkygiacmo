import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:my_app/core/routes/app_routes.dart';
import 'package:my_app/core/routes/auth_route_guard.dart';
import 'package:my_app/models/user_model.dart';
import 'package:my_app/providers/auth_provider.dart';
import 'package:my_app/services/auth_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('unfinished onboarding redirects to Onboarding', () async {
    final auth = await _createAuth();
    final guard = _guard(auth, onboardingCompleted: false);

    expect(
      await guard.redirect(Uri.parse(AppRoutes.home)),
      '${AppRoutes.onboarding}?from=%2Fhome',
    );
  });

  test('completed onboarding and unauthenticated user goes to Login', () async {
    final auth = await _createAuth();
    final guard = _guard(auth);

    expect(await guard.redirect(Uri.parse(AppRoutes.splash)), AppRoutes.login);
  });

  test('direct Home link is protected', () async {
    final auth = await _createAuth();
    final guard = _guard(auth);

    expect(
      await guard.redirect(Uri.parse(AppRoutes.home)),
      '${AppRoutes.login}?from=%2Fhome',
    );
  });

  test('direct Dream Detail link preserves path and query', () async {
    final auth = await _createAuth();
    final guard = _guard(auth);

    expect(
      await guard.redirect(Uri.parse('/dream-detail/dream-123?tab=notes')),
      '${AppRoutes.login}?from=%2Fdream-detail%2Fdream-123%3Ftab%3Dnotes',
    );
  });

  test('direct Edit Dream and Sleep Tracking links are protected', () async {
    final auth = await _createAuth();
    final guard = _guard(auth);

    for (final location in [
      '/edit-dream/dream-456?source=history',
      AppRoutes.sleepTracking,
    ]) {
      expect(
        await guard.redirect(Uri.parse(location)),
        '${AppRoutes.login}?from=${Uri.encodeQueryComponent(location)}',
      );
    }
  });

  test('authenticated user can open Home', () async {
    final auth = await _createAuth(authenticated: true);
    final guard = _guard(auth);

    expect(await guard.redirect(Uri.parse(AppRoutes.home)), isNull);
  });

  test('authenticated user opening Login is sent to Home', () async {
    final auth = await _createAuth(authenticated: true);
    final guard = _guard(auth);

    expect(await guard.redirect(Uri.parse(AppRoutes.login)), AppRoutes.home);
  });

  testWidgets('logout refreshes router and returns from Home to Login', (
    tester,
  ) async {
    final auth = await _createAuth(authenticated: true);
    final guard = _guard(auth);
    final router = _testRouter(auth, guard, initialLocation: AppRoutes.home);
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    expect(find.text('HOME_ROUTE'), findsOneWidget);

    await auth.logout();
    await tester.pumpAndSettle();

    expect(find.text('LOGIN_ROUTE'), findsOneWidget);
    expect(router.routeInformationProvider.value.uri.path, AppRoutes.login);
  });

  test(
    'auth restoration loading waits on Splash and preserves target',
    () async {
      final service = _FakeAuth()..initGate = Completer<void>();
      final auth = AuthProvider(authService: service);
      final restoration = auth.checkAuthStatus();
      final guard = _guard(auth);

      expect(auth.status, AuthStatus.loading);
      expect(
        await guard.redirect(Uri.parse(AppRoutes.sleepTracking)),
        '${AppRoutes.splash}?from=%2Fsleep-tracking',
      );

      service.initGate!.complete();
      await restoration;
      expect(
        await guard.redirect(Uri.parse(AppRoutes.splash)),
        AppRoutes.login,
      );
    },
  );

  test('restored authenticated session leaves Splash for Home', () async {
    final auth = await _createAuth(authenticated: true);
    final guard = _guard(auth);

    expect(await guard.redirect(Uri.parse(AppRoutes.splash)), AppRoutes.home);
  });

  test(
    'successful mock registration remains unauthenticated on Register',
    () async {
      final auth = await _createAuth();
      final guard = _guard(auth);

      expect(
        await auth.register(
          email: 'person@example.com',
          password: 'password123',
          name: 'Dream User',
        ),
        isTrue,
      );
      expect(auth.isAuthenticated, isFalse);
      expect(await guard.redirect(Uri.parse(AppRoutes.register)), isNull);
    },
  );
}

AuthRouteGuard _guard(AuthProvider auth, {bool onboardingCompleted = true}) =>
    AuthRouteGuard(
      authProvider: auth,
      onboardingStatusReader: () async => onboardingCompleted,
    );

Future<AuthProvider> _createAuth({bool authenticated = false}) async {
  final service = _FakeAuth()..user = authenticated ? _testUser : null;
  final auth = AuthProvider(authService: service);
  await auth.checkAuthStatus();
  return auth;
}

GoRouter _testRouter(
  AuthProvider auth,
  AuthRouteGuard guard, {
  required String initialLocation,
}) => GoRouter(
  initialLocation: initialLocation,
  refreshListenable: auth,
  redirect: (context, state) => guard.redirect(state.uri),
  routes: [
    GoRoute(
      path: AppRoutes.splash,
      builder: (context, state) => const Text('SPLASH_ROUTE'),
    ),
    GoRoute(
      path: AppRoutes.onboarding,
      builder: (context, state) => const Text('ONBOARDING_ROUTE'),
    ),
    GoRoute(
      path: AppRoutes.login,
      builder: (context, state) => const Text('LOGIN_ROUTE'),
    ),
    GoRoute(
      path: AppRoutes.home,
      builder: (context, state) => const Text('HOME_ROUTE'),
    ),
    GoRoute(
      path: '${AppRoutes.dreamDetail}/:id',
      builder: (context, state) => const Text('DETAIL_ROUTE'),
    ),
    GoRoute(
      path: AppRoutes.sleepTracking,
      builder: (context, state) => const Text('SLEEP_ROUTE'),
    ),
  ],
);

final _testUser = UserModel(
  id: 'user-uuid',
  email: 'person@example.com',
  name: 'Dream User',
  createdAt: DateTime.utc(2026),
);

class _FakeAuth implements AuthOperations {
  UserModel? user;
  Completer<void>? initGate;

  @override
  UserModel? get currentUser => user;

  @override
  String? get token => user == null ? null : 'mock-token';

  @override
  bool get isAuthenticated => user != null;

  @override
  Future<void> init() async => initGate?.future;

  @override
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    user = _testUser;
    return user!;
  }

  @override
  Future<UserModel> register({
    required String email,
    required String password,
    required String name,
  }) async => _testUser;

  @override
  Future<void> forgotPassword(String email) async {}

  @override
  Future<void> updateUser(UserModel updatedUser) async {
    user = updatedUser;
  }

  @override
  Future<void> logout() async {
    user = null;
  }
}
