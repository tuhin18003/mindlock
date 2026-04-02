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

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
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
    if (value.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  Future<void> _onSignIn() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final notifier = ref.read(authStateNotifierProvider.notifier);
    await notifier.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
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
    }
    // On success, GoRouter redirect handles navigation to dashboard/onboarding
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateNotifierProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      backgroundColor: AppColors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xxl,
            vertical: AppSpacing.xxxl,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppSpacing.vGap(AppSpacing.xxl),
                // Header
                Text('Welcome back', style: AppTypography.h1),
                AppSpacing.vGap(AppSpacing.sm),
                Text(
                  'Sign in to continue your focus journey.',
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
                // Password
                MlTextField(
                  label: 'Password',
                  hint: 'Your password',
                  controller: _passwordController,
                  obscureText: true,
                  prefixIcon: Icons.lock_outline_rounded,
                  focusNode: _passwordFocus,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _onSignIn(),
                  validator: _validatePassword,
                  enabled: !isLoading,
                ),
                AppSpacing.vGap(AppSpacing.md),
                // Forgot password link
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: isLoading
                        ? null
                        : () => context.push(AppRoutes.forgotPassword),
                    child: Text(
                      'Forgot Password?',
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.brandPrimary,
                      ),
                    ),
                  ),
                ),
                AppSpacing.vGap(AppSpacing.xxxl),
                // Sign in button
                MlButton(
                  label: 'Sign In',
                  onPressed: isLoading ? null : _onSignIn,
                  isLoading: isLoading,
                  variant: MlButtonVariant.primary,
                  size: MlButtonSize.lg,
                ),
                AppSpacing.vGap(AppSpacing.xl),
                // Register link
                Center(
                  child: GestureDetector(
                    onTap: isLoading ? null : () => context.go(AppRoutes.register),
                    child: RichText(
                      text: TextSpan(
                        text: "Don't have an account? ",
                        style: AppTypography.bodyMedium,
                        children: [
                          TextSpan(
                            text: 'Register',
                            style: AppTypography.labelMedium.copyWith(
                              color: AppColors.brandPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                AppSpacing.vGap(AppSpacing.xxl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
