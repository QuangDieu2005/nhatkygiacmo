import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:my_app/core/theme/app_theme.dart';
import 'package:my_app/features/authentication/presentation/forgot_password_screen.dart';
import 'package:my_app/features/authentication/presentation/login_screen.dart';
import 'package:my_app/features/authentication/presentation/register_screen.dart';
import 'package:my_app/features/dream_diary/presentation/dream_list_screen.dart';
import 'package:my_app/features/history/presentation/history_screen.dart';
import 'package:my_app/features/profile/presentation/profile_screen.dart';
import 'package:my_app/providers/auth_provider.dart';
import 'package:my_app/providers/dream_provider.dart';
import 'package:my_app/providers/sleep_provider.dart';
import 'package:my_app/shared/widgets/main_shell.dart';

const _widths = <double>[320, 375, 768, 1024];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('responsive screen layouts', () {
    testWidgets('forgot password scrolls with a short keyboard viewport', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 420);
      tester.view.devicePixelRatio = 1;
      tester.view.viewInsets = const FakeViewPadding(bottom: 260);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);

      await _pumpScreen(
        tester,
        const ForgotPasswordScreen(),
        width: 320,
        height: 420,
        textScale: 1.3,
      );
      final submit = find.text('Gửi yêu cầu');
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await tester.pumpAndSettle();

      expect(submit, findsOneWidget);
      _expectNoFrameworkException(tester, 'forgot password 320×420');
    });

    testWidgets('profile fits narrow screens with enlarged text', (
      tester,
    ) async {
      for (final width in const <double>[320, 375]) {
        await _pumpScreen(
          tester,
          const ProfileScreen(),
          width: width,
          textScale: 1.5,
        );
        expect(find.text('Thời lượng ngủ mục tiêu:'), findsOneWidget);
        expect(find.text('8 giờ / đêm'), findsOneWidget);
        _expectNoFrameworkException(tester, 'profile width $width');
      }
    });

    testWidgets('main shell keeps all five tabs usable at target widths', (
      tester,
    ) async {
      final router = _createShellRouter();
      addTearDown(router.dispose);

      for (final width in _widths) {
        await _setViewport(tester, width);
        await tester.pumpWidget(
          MaterialApp.router(
            theme: AppTheme.darkTheme,
            routerConfig: router,
            builder: (context, child) => _withTextScale(context, child, 1.3),
          ),
        );
        await tester.pumpAndSettle();

        for (final label in const [
          'Trang chủ',
          'Giấc mơ',
          'Giấc ngủ',
          'Phân tích',
          'Cá nhân',
        ]) {
          expect(find.text(label), findsOneWidget);
        }
        await tester.tap(find.text('Cá nhân'));
        await tester.pumpAndSettle();
        expect(find.text('branch-4'), findsOneWidget);
        _expectNoFrameworkException(tester, 'main shell width $width');
      }
    });

    testWidgets('history filters remain horizontally reachable', (
      tester,
    ) async {
      for (final width in _widths) {
        await _pumpScreen(
          tester,
          const HistoryScreen(),
          width: width,
          textScale: 1.3,
        );

        final lastFilter = find.text('30 ngày qua');
        await tester.ensureVisible(lastFilter);
        await tester.tap(lastFilter);
        await tester.pumpAndSettle();
        final chip = tester.widget<ChoiceChip>(
          find.ancestor(of: lastFilter, matching: find.byType(ChoiceChip)),
        );
        expect(chip.selected, isTrue);
        _expectNoFrameworkException(tester, 'history width $width');
      }
    });

    testWidgets('login form stays usable and constrained on target widths', (
      tester,
    ) async {
      for (final width in _widths) {
        await _pumpScreen(
          tester,
          const LoginScreen(),
          width: width,
          textScale: 1.2,
        );
        expect(find.text('Đăng nhập'), findsWidgets);
        expect(find.byType(TextFormField), findsNWidgets(2));
        if (width > 520) {
          expect(
            tester.getSize(find.byType(Form).first).width,
            lessThanOrEqualTo(520),
          );
        }
        _expectNoFrameworkException(tester, 'login width $width');
      }
    });

    testWidgets('register form stays usable and constrained on target widths', (
      tester,
    ) async {
      for (final width in _widths) {
        await _pumpScreen(
          tester,
          const RegisterScreen(),
          width: width,
          textScale: 1.2,
        );
        expect(find.text('Tạo tài khoản'), findsWidgets);
        expect(find.byType(TextFormField), findsNWidgets(4));
        if (width > 520) {
          expect(
            tester.getSize(find.byType(Form).first).width,
            lessThanOrEqualTo(520),
          );
        }
        _expectNoFrameworkException(tester, 'register width $width');
      }
    });

    testWidgets('dream list stays usable and constrained on target widths', (
      tester,
    ) async {
      for (final width in _widths) {
        await _pumpScreen(
          tester,
          const DreamListScreen(),
          width: width,
          textScale: 1.2,
        );
        expect(find.byType(TextField), findsOneWidget);
        expect(find.text('Lọc theo cảm xúc'), findsOneWidget);
        if (width > 760) {
          expect(
            tester.getSize(find.byType(CustomScrollView).first).width,
            lessThanOrEqualTo(760),
          );
        }
        _expectNoFrameworkException(tester, 'dream list width $width');
      }
    });
  });
}

Future<void> _pumpScreen(
  WidgetTester tester,
  Widget screen, {
  double width = 375,
  double height = 800,
  double textScale = 1,
}) async {
  await _setViewport(tester, width, height: height);
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => DreamProvider()),
        ChangeNotifierProvider(create: (_) => SleepProvider()),
      ],
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        home: screen,
        builder: (context, child) => _withTextScale(context, child, textScale),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _setViewport(
  WidgetTester tester,
  double width, {
  double height = 800,
}) async {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1;
}

Widget _withTextScale(BuildContext context, Widget? child, double scale) {
  return MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
    child: child ?? const SizedBox.shrink(),
  );
}

void _expectNoFrameworkException(WidgetTester tester, String description) {
  final exception = tester.takeException();
  expect(exception, isNull, reason: '$description: $exception');
}

GoRouter _createShellRouter() {
  return GoRouter(
    initialLocation: '/branch-0',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => MainShell(navigationShell: shell),
        branches: [
          for (var index = 0; index < 5; index++)
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/branch-$index',
                  builder: (context, state) =>
                      Scaffold(body: Center(child: Text('branch-$index'))),
                ),
              ],
            ),
        ],
      ),
    ],
  );
}
