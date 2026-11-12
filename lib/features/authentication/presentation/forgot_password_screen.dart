import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
  bool _submitted = false;
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
        setState(() => _submitted = true);
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
                    child: _submitted ? _buildSuccessView() : _buildFormView(),
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
            'Nh\u1eadp email \u0111\u00e3 \u0111\u0103ng k\u00fd. Ch\u00fang t\u00f4i s\u1ebd g\u1eedi h\u01b0\u1edbng d\u1eabn \u0111\u1eb7t l\u1ea1i m\u1eadt kh\u1ea9u cho b\u1ea1n.',
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

  Widget _buildSuccessView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_outline_rounded,
              color: AppColors.success,
              size: 56,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Y\u00eau c\u1ea7u kh\u00f4i ph\u1ee5c demo \u0111\u00e3 \u0111\u01b0\u1ee3c ghi nh\u1eadn',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'AuthService hi\u1ec7n ch\u1ec9 m\u00f4 ph\u1ecfng thao t\u00e1c. Kh\u00f4ng c\u00f3 email th\u1eadt \u0111\u01b0\u1ee3c g\u1eedi \u0111\u1ebfn ' +
                _emailController.text +
                '.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          AppButton(
            label: 'Quay l\u1ea1i \u0111\u0103ng nh\u1eadp',
            onPressed: () => context.pop(),
          ),
        ],
      ),
    );
  }
}
