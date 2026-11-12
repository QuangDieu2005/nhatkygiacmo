import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/utils/validators.dart';
import '../../../providers/auth_provider.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.register(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      name: _nameController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      context.go(AppRoutes.home);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            authProvider.errorMessage ?? 'Đăng ký không thành công',
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tạo tài khoản')),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.nightSkyGradient),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Bắt đầu hành trình',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Ghi lại từng khoảnh khắc giấc mơ tuyệt đẹp',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 30),

                        // Tên người dùng
                        AppTextField(
                          controller: _nameController,
                          label: 'Họ và tên',
                          hint: 'Nhập tên của bạn',
                          prefixIcon: Icons.person_outline,
                          validator: (val) =>
                              Validators.validateRequired(val, 'họ và tên'),
                        ),
                        const SizedBox(height: 16),

                        // Email
                        AppTextField(
                          controller: _emailController,
                          label: 'Địa chỉ Email',
                          hint: 'example@email.com',
                          prefixIcon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: Validators.validateEmail,
                        ),
                        const SizedBox(height: 16),

                        // Mật khẩu
                        AppTextField(
                          controller: _passwordController,
                          label: 'Mật khẩu',
                          hint: 'Ít nhất 6 ký tự',
                          prefixIcon: Icons.lock_outline,
                          obscureText: true,
                          validator: Validators.validatePassword,
                        ),
                        const SizedBox(height: 16),

                        // Nhập lại mật khẩu
                        AppTextField(
                          controller: _confirmPasswordController,
                          label: 'Xác nhận mật khẩu',
                          hint: 'Nhập lại mật khẩu',
                          prefixIcon: Icons.lock_clock_outlined,
                          obscureText: true,
                          validator: (val) =>
                              Validators.validateConfirmPassword(
                                val,
                                _passwordController.text,
                              ),
                        ),
                        const SizedBox(height: 32),

                        // Nút Đăng ký
                        Consumer<AuthProvider>(
                          builder: (context, auth, _) {
                            return AppButton(
                              label: 'Tạo tài khoản',
                              isLoading: auth.status == AuthStatus.loading,
                              onPressed: _handleRegister,
                            );
                          },
                        ),
                        const SizedBox(height: 20),

                        // Đã có tài khoản
                        Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          runAlignment: WrapAlignment.center,
                          children: [
                            const Text(
                              'Đã có tài khoản? ',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => context.pop(),
                              child: const Text(
                                'Đăng nhập',
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
