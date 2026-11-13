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
  bool _isSubmitting = false;
  bool _registrationComplete = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (_isSubmitting ||
        context.read<AuthProvider>().status == AuthStatus.loading) {
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    setState(() => _isSubmitting = true);
    try {
      final success = await authProvider.register(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
      );
      if (!mounted) return;

      if (success && authProvider.isAuthenticated) {
        context.go(AppRoutes.home);
      } else if (success) {
        setState(() => _registrationComplete = true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              authProvider.errorMessage ??
                  '\u0110\u0103ng k\u00fd kh\u00f4ng th\u00e0nh c\u00f4ng',
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
      appBar: AppBar(title: const Text('T\u1ea1o t\u00e0i kho\u1ea3n')),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.nightSkyGradient),
        child: SafeArea(
          child: _registrationComplete
              ? _buildRegistrationComplete()
              : Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 20,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 520),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'B\u1eaft \u0111\u1ea7u h\u00e0nh tr\u00ecnh',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Ghi l\u1ea1i t\u1eebng kho\u1ea3nh kh\u1eafc gi\u1ea5c m\u01a1 tuy\u1ec7t \u0111\u1eb9p',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 30),

                              // TÃƒÂªn ngÃ†Â°Ã¡Â»Âi dÃƒÂ¹ng
                              AppTextField(
                                controller: _nameController,
                                label: 'H\u1ecd v\u00e0 t\u00ean',
                                hint: 'Nh\u1eadp t\u00ean c\u1ee7a b\u1ea1n',
                                prefixIcon: Icons.person_outline,
                                validator: (val) => Validators.validateRequired(
                                  val,
                                  'h\u1ecd v\u00e0 t\u00ean',
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Email
                              AppTextField(
                                controller: _emailController,
                                label: '\u0110\u1ecba ch\u1ec9 Email',
                                hint: 'example@email.com',
                                prefixIcon: Icons.email_outlined,
                                keyboardType: TextInputType.emailAddress,
                                validator: Validators.validateEmail,
                              ),
                              const SizedBox(height: 16),

                              // MÃ¡ÂºÂ­t khÃ¡ÂºÂ©u
                              AppTextField(
                                controller: _passwordController,
                                label: 'M\u1eadt kh\u1ea9u',
                                hint: '\u00cdt nh\u1ea5t 6 k\u00fd t\u1ef1',
                                prefixIcon: Icons.lock_outline,
                                obscureText: true,
                                validator: Validators.validatePassword,
                              ),
                              const SizedBox(height: 16),

                              // NhÃ¡ÂºÂ­p lÃ¡ÂºÂ¡i mÃ¡ÂºÂ­t khÃ¡ÂºÂ©u
                              AppTextField(
                                controller: _confirmPasswordController,
                                label: 'X\u00e1c nh\u1eadn m\u1eadt kh\u1ea9u',
                                hint: 'Nh\u1eadp l\u1ea1i m\u1eadt kh\u1ea9u',
                                prefixIcon: Icons.lock_clock_outlined,
                                obscureText: true,
                                validator: (val) =>
                                    Validators.validateConfirmPassword(
                                      val,
                                      _passwordController.text,
                                    ),
                              ),
                              const SizedBox(height: 32),

                              // NÃƒÂºt Ã„ÂÃ„Æ’ng kÃƒÂ½
                              Consumer<AuthProvider>(
                                builder: (context, auth, _) {
                                  return AppButton(
                                    label: 'T\u1ea1o t\u00e0i kho\u1ea3n',
                                    isLoading:
                                        _isSubmitting ||
                                        auth.status == AuthStatus.loading,
                                    onPressed: _handleRegister,
                                  );
                                },
                              ),
                              const SizedBox(height: 20),

                              // Ã„ÂÃƒÂ£ cÃƒÂ³ tÃƒÂ i khoÃ¡ÂºÂ£n
                              Wrap(
                                alignment: WrapAlignment.center,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                runAlignment: WrapAlignment.center,
                                children: [
                                  const Text(
                                    '\u0110\u00e3 c\u00f3 t\u00e0i kho\u1ea3n? ',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 14,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => context.pop(),
                                    child: const Text(
                                      '\u0110\u0103ng nh\u1eadp',
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

  Widget _buildRegistrationComplete() => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.mark_email_unread_outlined,
              color: AppColors.primaryLight,
              size: 54,
            ),
            const SizedBox(height: 18),
            const Text(
              'Vui l\u00f2ng x\u00e1c nh\u1eadn email c\u1ee7a b\u1ea1n',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Y\u00eau c\u1ea7u \u0111\u0103ng k\u00fd c\u1ea7n x\u00e1c nh\u1eadn email. N\u1ebfu \u0111\u1ecba ch\u1ec9 n\u00e0y h\u1ee3p l\u1ec7, h\u00e3y ki\u1ec3m tra h\u1ed9p th\u01b0 v\u00e0 x\u00e1c nh\u1eadn tr\u01b0\u1edbc khi \u0111\u0103ng nh\u1eadp.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 24),
            AppButton(
              label: 'Quay l\u1ea1i \u0111\u0103ng nh\u1eadp',
              onPressed: () => context.go(AppRoutes.login),
            ),
          ],
        ),
      ),
    ),
  );
}
