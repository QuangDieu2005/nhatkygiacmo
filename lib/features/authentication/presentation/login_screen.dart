import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/utils/validators.dart';
import '../../../providers/auth_provider.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_isSubmitting ||
        context.read<AuthProvider>().status == AuthStatus.loading) {
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    setState(() => _isSubmitting = true);
    try {
      final success = await authProvider.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      if (success) {
        final requestedLocation = GoRouterState.of(context)
            .uri
            .queryParameters['from'];
        context.go(AppRoutes.locationAfterLogin(requestedLocation));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              authProvider.errorMessage ?? 'Đăng nhập không thành công',
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.nightSkyGradient),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Icon Logo
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.15),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primary.withOpacity(0.3),
                            ),
                          ),
                          child: const Icon(
                            Icons.nights_stay_rounded,
                            size: 48,
                            color: AppColors.primaryLight,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Chào mừng trở lại',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Đăng nhập để xem nhật ký giấc mơ của bạn',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Consumer<AuthProvider>(
                          builder: (context, auth, _) {
                            if (!auth.isInitialized ||
                                auth.status != AuthStatus.unauthenticated ||
                                auth.errorMessage == null) {
                              return const SizedBox.shrink();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(top: 16),
                              child: Column(
                                children: [
                                  Text(
                                    auth.errorMessage!,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: AppColors.error,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: auth.status == AuthStatus.loading
                                        ? null
                                        : auth.retryRestoreSession,
                                    child: const Text('Thử khôi phục phiên'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 36),

                        // Input Email
                        AppTextField(
                          controller: _emailController,
                          label: 'Địa chỉ Email',
                          hint: 'example@email.com',
                          prefixIcon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: Validators.validateEmail,
                        ),
                        const SizedBox(height: 16),

                        // Input Password
                        AppTextField(
                          controller: _passwordController,
                          label: 'Mật khẩu',
                          hint: 'Nhập mật khẩu',
                          prefixIcon: Icons.lock_outline,
                          obscureText: true,
                          validator: Validators.validatePassword,
                        ),
                        const SizedBox(height: 12),

                        // Quên mật khẩu
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () =>
                                context.push(AppRoutes.forgotPassword),
                            child: const Text(
                              'Quên mật khẩu?',
                              style: TextStyle(
                                color: AppColors.primaryLight,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Nút Đăng nhập
                        Consumer<AuthProvider>(
                          builder: (context, auth, _) {
                            return AppButton(
                              label: 'Đăng nhập',
                              isLoading:
                                  _isSubmitting ||
                                  auth.status == AuthStatus.loading,
                              onPressed: _handleLogin,
                            );
                          },
                        ),
                        const SizedBox(height: 24),

                        // Chuyển sang đăng ký
                        Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          runAlignment: WrapAlignment.center,
                          children: [
                            const Text(
                              'Chưa có tài khoản? ',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => context.push(AppRoutes.register),
                              child: const Text(
                                'Đăng ký ngay',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
