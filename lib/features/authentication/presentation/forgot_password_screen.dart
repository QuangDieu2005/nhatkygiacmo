import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../providers/auth_provider.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    if (_isSubmitting ||
        context.read<AuthProvider>().status == AuthStatus.loading) {
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    setState(() => _isSubmitting = true);
    try {
      final success = await authProvider.forgotPassword(
        _emailController.text.trim(),
      );
      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Yêu cầu khôi phục đã được xử lý.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              authProvider.errorMessage ?? 'Kh\u00f4ng th\u1ec3 x\u1eed l\u00fd y\u00eau c\u1ea7u kh\u00f4i ph\u1ee5c.',
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
      appBar: AppBar(
        title: const Text('Kh\u00f4i ph\u1ee5c m\u1eadt kh\u1ea9u'),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.nightSkyGradient),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight > 48
                      ? constraints.maxHeight - 48
                      : 0,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: _buildFormView(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormView() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Qu\u00ean m\u1eadt kh\u1ea9u?',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Kh\u00f4i ph\u1ee5c m\u1eadt kh\u1ea9u ch\u01b0a \u0111\u01b0\u1ee3c h\u1ed7 tr\u1ee3. Backend ch\u01b0a c\u00f3 ch\u1ee9c n\u0103ng g\u1eedi email; y\u00eau c\u1ea7u s\u1ebd kh\u00f4ng \u0111\u01b0\u1ee3c g\u1eedi khi b\u1ea5m n\u00fat.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          AppTextField(
            controller: _emailController,
            label: '\u0110\u1ecba ch\u1ec9 Email',
            hint: 'example@email.com',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: Validators.validateEmail,
          ),
          const SizedBox(height: 28),
          Consumer<AuthProvider>(
            builder: (context, auth, _) {
              return AppButton(
                label: 'G\u1eedi y\u00eau c\u1ea7u',
                isLoading: _isSubmitting || auth.status == AuthStatus.loading,
                onPressed: _handleResetPassword,
              );
            },
          ),
        ],
      ),
    );
  }
}
