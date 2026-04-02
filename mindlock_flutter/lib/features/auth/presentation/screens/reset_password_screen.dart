import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/ml_button.dart';
import '../../../../shared/widgets/ml_text_field.dart';
import '../../../../routes/app_routes.dart';
import '../providers/auth_provider.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  final String token;

  const ResetPasswordScreen({super.key, required this.token});

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmPasswordFocus = FocusNode();
  bool _resetSuccess = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(value.trim())) return 'Enter a valid email';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 8) return 'Password must be at least 8 characters';
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) return 'Please confirm your password';
    if (value != _passwordController.text) return 'Passwords do not match';
    return null;
  }

  Future<void> _onResetPassword() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final notifier = ref.read(authStateNotifierProvider.notifier);
    await notifier.resetPassword(
      token: widget.token,
      email: _emailController.text.trim(),
      password: _passwordController.text,
      passwordConfirmation: _confirmPasswordController.text,
    );

    if (!mounted) return;

    final authState = ref.read(authStateNotifierProvider);
    if (authState.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authState.error!),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(AppSpacing.lg),
          shape: RoundedRectangleBorder(borderRadius: AppSpacing.borderRadiusMd),
        ),
      );
    } else {
      setState(() => _resetSuccess = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateNotifierProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        backgroundColor: AppColors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary, size: 20),
          onPressed: () => context.go(AppRoutes.login),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xxl,
            vertical: AppSpacing.xl,
          ),
          child: _resetSuccess ? _buildSuccessState() : _buildFormState(isLoading),
        ),
      ),
    );
  }

  Widget _buildFormState(bool isLoading) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSpacing.vGap(AppSpacing.xl),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: AppSpacing.borderRadiusLg,
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(
              Icons.lock_open_rounded,
              size: 32,
              color: AppColors.brandPrimary,
            ),
          ),
          AppSpacing.vGap(AppSpacing.xxl),
          Text('Reset password', style: AppTypography.h1),
          AppSpacing.vGap(AppSpacing.sm),
          Text(
            'Enter your email and choose a new password.',
            style: AppTypography.bodyMedium,
          ),
          AppSpacing.vGap(AppSpacing.huge),
          // Email
          MlTextField(
            label: 'Email',
            hint: 'you@example.com',
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icons.email_outlined,
            focusNode: _emailFocus,
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => _passwordFocus.requestFocus(),
            validator: _validateEmail,
            enabled: !isLoading,
          ),
          AppSpacing.vGap(AppSpacing.lg),
          // New Password
          MlTextField(
            label: 'New Password',
            hint: 'Min. 8 characters',
            controller: _passwordController,
            obscureText: true,
            prefixIcon: Icons.lock_outline_rounded,
            focusNode: _passwordFocus,
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => _confirmPasswordFocus.requestFocus(),
            validator: _validatePassword,
            enabled: !isLoading,
          ),
          AppSpacing.vGap(AppSpacing.lg),
          // Confirm Password
          MlTextField(
            label: 'Confirm New Password',
            hint: 'Repeat your new password',
            controller: _confirmPasswordController,
            obscureText: true,
            prefixIcon: Icons.lock_outline_rounded,
            focusNode: _confirmPasswordFocus,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _onResetPassword(),
            validator: _validateConfirmPassword,
            enabled: !isLoading,
          ),
          AppSpacing.vGap(AppSpacing.xxxl),
          MlButton(
            label: 'Reset Password',
            onPressed: isLoading ? null : _onResetPassword,
            isLoading: isLoading,
            variant: MlButtonVariant.primary,
            size: MlButtonSize.lg,
          ),
          AppSpacing.vGap(AppSpacing.xl),
          Center(
            child: GestureDetector(
              onTap: isLoading ? null : () => context.go(AppRoutes.login),
              child: RichText(
                text: TextSpan(
                  text: '← ',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.brandPrimary,
                  ),
                  children: [
                    TextSpan(
                      text: 'Back to Login',
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.brandPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        AppSpacing.vGap(AppSpacing.huge),
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.successSurface,
            borderRadius: AppSpacing.borderRadiusFull,
            border: Border.all(color: AppColors.success.withOpacity(0.3)),
          ),
          child: const Icon(
            Icons.check_circle_outline_rounded,
            size: 40,
            color: AppColors.success,
          ),
        ),
        AppSpacing.vGap(AppSpacing.xxl),
        Text(
          'Password reset!',
          style: AppTypography.h2,
          textAlign: TextAlign.center,
        ),
        AppSpacing.vGap(AppSpacing.md),
        Text(
          'Your password has been successfully updated.\nYou can now sign in with your new password.',
          style: AppTypography.bodyMedium,
          textAlign: TextAlign.center,
        ),
        AppSpacing.vGap(AppSpacing.huge),
        MlButton(
          label: 'Sign In',
          onPressed: () => context.go(AppRoutes.login),
          variant: MlButtonVariant.primary,
          size: MlButtonSize.lg,
        ),
      ],
    );
  }
}
