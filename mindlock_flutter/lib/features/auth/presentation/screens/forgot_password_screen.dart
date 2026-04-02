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

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(value.trim())) return 'Enter a valid email';
    return null;
  }

  Future<void> _onSendResetLink() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final notifier = ref.read(authStateNotifierProvider.notifier);
    await notifier.forgotPassword(email: _emailController.text.trim());

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
      setState(() => _emailSent = true);
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
          onPressed: () => context.canPop() ? context.pop() : context.go(AppRoutes.login),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xxl,
            vertical: AppSpacing.xl,
          ),
          child: _emailSent ? _buildSuccessState() : _buildFormState(isLoading),
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
          // Icon
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: AppSpacing.borderRadiusLg,
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(
              Icons.lock_reset_rounded,
              size: 32,
              color: AppColors.brandPrimary,
            ),
          ),
          AppSpacing.vGap(AppSpacing.xxl),
          Text('Forgot password?', style: AppTypography.h1),
          AppSpacing.vGap(AppSpacing.sm),
          Text(
            'No worries. Enter your email and we\'ll send you a reset link.',
            style: AppTypography.bodyMedium,
          ),
          AppSpacing.vGap(AppSpacing.huge),
          MlTextField(
            label: 'Email',
            hint: 'you@example.com',
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icons.email_outlined,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _onSendResetLink(),
            validator: _validateEmail,
            enabled: !isLoading,
          ),
          AppSpacing.vGap(AppSpacing.xxxl),
          MlButton(
            label: 'Send Reset Link',
            onPressed: isLoading ? null : _onSendResetLink,
            isLoading: isLoading,
            variant: MlButtonVariant.primary,
            size: MlButtonSize.lg,
          ),
          AppSpacing.vGap(AppSpacing.xl),
          Center(
            child: GestureDetector(
              onTap: isLoading
                  ? null
                  : () => context.canPop()
                      ? context.pop()
                      : context.go(AppRoutes.login),
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
            Icons.mark_email_read_outlined,
            size: 40,
            color: AppColors.success,
          ),
        ),
        AppSpacing.vGap(AppSpacing.xxl),
        Text('Check your inbox', style: AppTypography.h2, textAlign: TextAlign.center),
        AppSpacing.vGap(AppSpacing.md),
        Text(
          'We sent a password reset link to\n${_emailController.text.trim()}',
          style: AppTypography.bodyMedium,
          textAlign: TextAlign.center,
        ),
        AppSpacing.vGap(AppSpacing.sm),
        Text(
          'Check your spam folder if you don\'t see it.',
          style: AppTypography.bodySmall,
          textAlign: TextAlign.center,
        ),
        AppSpacing.vGap(AppSpacing.huge),
        MlButton(
          label: 'Back to Login',
          onPressed: () => context.go(AppRoutes.login),
          variant: MlButtonVariant.primary,
          size: MlButtonSize.lg,
        ),
        AppSpacing.vGap(AppSpacing.xl),
        Center(
          child: GestureDetector(
            onTap: () => setState(() => _emailSent = false),
            child: Text(
              'Resend email',
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
