import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:my_app/core/routes/app_routes.dart';
import 'package:my_app/core/theme/app_theme.dart';
import 'package:my_app/features/authentication/presentation/forgot_password_screen.dart';
import 'package:my_app/features/authentication/presentation/login_screen.dart';
import 'package:my_app/features/authentication/presentation/register_screen.dart';
import 'package:my_app/models/user_model.dart';
import 'package:my_app/providers/auth_provider.dart';
import 'package:my_app/services/auth_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Login fields start empty and password visibility toggles', (
    tester,
  ) async {
    await _pumpRouter(tester, _FakeAuth());
    expect(_field(tester, 0).controller!.text, isEmpty);
    expect(_field(tester, 1).controller!.text, isEmpty);
    expect(_obscureText(tester, 1), isTrue);
    await tester.tap(find.byIcon(Icons.visibility_outlined).first);
    await tester.pump();
    expect(_obscureText(tester, 1), isFalse);
  });

  testWidgets('Login validation blocks invalid values before service call', (
    tester,
  ) async {
    final service = _FakeAuth();
    await _pumpRouter(tester, service);
    await tester.enterText(find.byType(TextFormField).at(0), 'bad-email');
    await tester.enterText(find.byType(TextFormField).at(1), '123');
    await tester.tap(find.byType(ElevatedButton).last);
    await tester.pumpAndSettle();
    expect(service.loginCalls, 0);
    expect(_fieldState(tester, 0).errorText, isNotNull);
    expect(_fieldState(tester, 1).errorText, isNotNull);
  });

  testWidgets('Login shows loading and blocks duplicate submission', (
    tester,
  ) async {
    final service = _FakeAuth()..loginGate = Completer<UserModel>();
    await _pumpRouter(tester, service);
    await _fillLogin(tester);
    await tester.tap(find.byType(ElevatedButton).last);
    await tester.pump();
    expect(service.loginCalls, 1);
    expect(
      tester.widget<ElevatedButton>(find.byType(ElevatedButton).last).onPressed,
      isNull,
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    service.loginGate!.complete(_user);
    await tester.pumpAndSettle();
    expect(find.text('HOME_MARKER'), findsOneWidget);
  });

  testWidgets('Login failure keeps user on login and shows an error', (
    tester,
  ) async {
    final service = _FakeAuth()..failLogin = true;
    await _pumpRouter(tester, service);
    await _fillLogin(tester);
    await tester.tap(find.byType(ElevatedButton).last);
    await tester.pumpAndSettle();
    expect(find.text('HOME_MARKER'), findsNothing);
    expect(find.byType(SnackBar), findsOneWidget);
  });

  testWidgets('Register validates required fields and password confirmation', (
    tester,
  ) async {
    final service = _FakeAuth();
    await _pumpRouter(tester, service, initialPath: AppRoutes.register);
    final submit = find.byType(ElevatedButton).last;
    await tester.ensureVisible(submit);
    await tester.pumpAndSettle();
    await tester.tap(submit);
    await tester.pumpAndSettle();
    expect(service.registerCalls, 0);
    for (var index = 0; index < 4; index++) {
      expect(_fieldState(tester, index).errorText, isNotNull);
    }
    await tester.enterText(find.byType(TextFormField).at(0), 'Dream User');
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'user@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(2), 'secret1');
    await tester.enterText(find.byType(TextFormField).at(3), 'different');
    await tester.ensureVisible(submit);
    await tester.pumpAndSettle();
    await tester.tap(submit);
    await tester.pumpAndSettle();
    expect(service.registerCalls, 0);
    expect(_fieldState(tester, 3).errorText, isNotNull);
    expect(find.byIcon(Icons.visibility_outlined), findsNWidgets(2));
  });

  testWidgets('Register loading disables repeated submission', (tester) async {
    final service = _FakeAuth()..registerGate = Completer<UserModel>();
    await _pumpRouter(tester, service, initialPath: AppRoutes.register);
    await _fillRegister(tester);
    await tester.tap(find.byType(ElevatedButton).last);
    await tester.pump();
    expect(service.registerCalls, 1);
    expect(
      tester.widget<ElevatedButton>(find.byType(ElevatedButton).last).onPressed,
      isNull,
    );
    service.registerGate!.complete(_user);
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.mark_email_unread_outlined), findsOneWidget);
  });

  testWidgets('Register failure does not navigate to home', (tester) async {
    final service = _FakeAuth()..failRegister = true;
    await _pumpRouter(tester, service, initialPath: AppRoutes.register);
    await _fillRegister(tester);
    await tester.tap(find.byType(ElevatedButton).last);
    await tester.pumpAndSettle();
    expect(service.registerCalls, 1);
    expect(find.text('HOME_MARKER'), findsNothing);
    expect(find.byType(SnackBar), findsOneWidget);
  });

  testWidgets(
    'Register mock success is not treated as verified authentication',
    (tester) async {
      final service = _FakeAuth();
      await _pumpRouter(tester, service, initialPath: AppRoutes.register);
      await _fillRegister(tester);
      await tester.tap(find.byType(ElevatedButton).last);
      await tester.pumpAndSettle();
      expect(find.text('HOME_MARKER'), findsNothing);
      expect(find.byIcon(Icons.mark_email_unread_outlined), findsOneWidget);
      expect(find.textContaining('mock'), findsOneWidget);
    },
  );

  testWidgets('Forgot password validates email before submitting', (
    tester,
  ) async {
    final service = _FakeAuth();
    await _pumpRouter(tester, service, initialPath: AppRoutes.forgotPassword);
    await tester.enterText(find.byType(TextFormField).first, 'invalid');
    await tester.tap(find.byType(ElevatedButton).last);
    await tester.pumpAndSettle();
    expect(service.forgotCalls, 0);
    expect(_fieldState(tester, 0).errorText, isNotNull);
  });

  testWidgets('Forgot password mock success is clearly labeled', (
    tester,
  ) async {
    final service = _FakeAuth();
    await _pumpRouter(tester, service, initialPath: AppRoutes.forgotPassword);
    await tester.enterText(
      find.byType(TextFormField).first,
      'user@example.com',
    );
    await tester.tap(find.byType(ElevatedButton).last);
    await tester.pumpAndSettle();
    expect(service.forgotCalls, 1);
    expect(find.byIcon(Icons.check_circle_outline_rounded), findsOneWidget);
    expect(find.textContaining('demo'), findsOneWidget);
    expect(find.textContaining('user@example.com'), findsOneWidget);
  });

  testWidgets('Forgot password failure is distinguishable from mock success', (
    tester,
  ) async {
    final service = _FakeAuth()..failForgot = true;
    await _pumpRouter(tester, service, initialPath: AppRoutes.forgotPassword);
    await tester.enterText(
      find.byType(TextFormField).first,
      'user@example.com',
    );
    await tester.tap(find.byType(ElevatedButton).last);
    await tester.pumpAndSettle();
    expect(service.forgotCalls, 1);
    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_outline_rounded), findsNothing);
  });

  testWidgets('Forgot password loading disables repeated submission', (
    tester,
  ) async {
    final service = _FakeAuth()..forgotGate = Completer<void>();
    await _pumpRouter(tester, service, initialPath: AppRoutes.forgotPassword);
    await tester.enterText(
      find.byType(TextFormField).first,
      'user@example.com',
    );
    await tester.tap(find.byType(ElevatedButton).last);
    await tester.pump();
    expect(service.forgotCalls, 1);
    expect(
      tester.widget<ElevatedButton>(find.byType(ElevatedButton).last).onPressed,
      isNull,
    );
    service.forgotGate!.complete();
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.check_circle_outline_rounded), findsOneWidget);
  });

  testWidgets(
    'All auth forms remain usable with keyboard inset on a short screen',
    (tester) async {
      tester.view.physicalSize = const Size(320, 420);
      tester.view.devicePixelRatio = 1;
      tester.view.viewInsets = const FakeViewPadding(bottom: 250);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);

      for (final screen in const <Widget>[
        LoginScreen(),
        RegisterScreen(),
        ForgotPasswordScreen(),
      ]) {
        await tester.pumpWidget(
          ChangeNotifierProvider(
            create: (_) => AuthProvider(authService: _FakeAuth()),
            child: MaterialApp(theme: AppTheme.darkTheme, home: screen),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(TextFormField), findsWidgets);
        expect(tester.takeException(), isNull);
      }
    },
  );
}

TextFormField _field(WidgetTester tester, int index) =>
    tester.widget<TextFormField>(find.byType(TextFormField).at(index));

bool _obscureText(WidgetTester tester, int index) => tester
    .widget<EditableText>(
      find.descendant(
        of: find.byType(TextFormField).at(index),
        matching: find.byType(EditableText),
      ),
    )
    .obscureText;

FormFieldState<String> _fieldState(WidgetTester tester, int index) =>
    tester.state<FormFieldState<String>>(find.byType(TextFormField).at(index));

Future<void> _fillLogin(WidgetTester tester) async {
  await tester.enterText(find.byType(TextFormField).at(0), 'user@example.com');
  await tester.enterText(find.byType(TextFormField).at(1), 'secret1');
}

Future<void> _fillRegister(WidgetTester tester) async {
  await tester.enterText(find.byType(TextFormField).at(0), 'Dream User');
  await tester.enterText(find.byType(TextFormField).at(1), 'user@example.com');
  await tester.enterText(find.byType(TextFormField).at(2), 'secret1');
  await tester.enterText(find.byType(TextFormField).at(3), 'secret1');
}

Future<void> _pumpRouter(
  WidgetTester tester,
  _FakeAuth service, {
  String initialPath = AppRoutes.login,
}) async {
  final router = GoRouter(
    initialLocation: initialPath,
    routes: [
      GoRoute(path: AppRoutes.login, builder: (_, _) => const LoginScreen()),
      GoRoute(
        path: AppRoutes.register,
        builder: (_, _) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (_, _) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (_, _) => const Scaffold(body: Text('HOME_MARKER')),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ChangeNotifierProvider(
      create: (_) => AuthProvider(authService: service),
      child: MaterialApp.router(
        theme: AppTheme.darkTheme,
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

final _user = UserModel(
  id: 'user-test',
  email: 'user@example.com',
  name: 'Dream User',
  createdAt: DateTime(2026, 1, 1),
);

class _FakeAuth implements AuthOperations {
  int loginCalls = 0;
  int registerCalls = 0;
  int forgotCalls = 0;
  bool failLogin = false;
  bool failRegister = false;
  bool failForgot = false;
  Completer<UserModel>? loginGate;
  Completer<UserModel>? registerGate;
  Completer<void>? forgotGate;
  UserModel? currentUser;
  String? token;

  @override
  bool get isAuthenticated => currentUser != null;
  @override
  Future<void> init() async {}
  @override
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    loginCalls++;
    if (loginGate != null) return loginGate!.future;
    if (failLogin) throw StateError('Login rejected');
    currentUser = _user;
    token = 'mock-token';
    return _user;
  }

  @override
  Future<UserModel> register({
    required String email,
    required String password,
    required String name,
  }) async {
    registerCalls++;
    if (failRegister) throw StateError('Registration rejected');
    if (registerGate != null) return registerGate!.future;
    return _user;
  }

  @override
  Future<void> forgotPassword(String email) async {
    forgotCalls++;
    if (failForgot) throw StateError('Reset request rejected');
    if (forgotGate != null) return forgotGate!.future;
  }

  @override
  Future<void> updateUser(UserModel updatedUser) async {
    currentUser = updatedUser;
  }

  @override
  Future<void> logout() async {
    currentUser = null;
    token = null;
  }
}
