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

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmPasswordFocus = FocusNode();
  bool _agreedToTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Name is required';
    if (value.trim().length < 2) return 'Name must be at least 2 characters';
    return null;
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

  Future<void> _onCreateAccount() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please agree to the Terms & Privacy Policy'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(AppSpacing.lg),
          shape: RoundedRectangleBorder(borderRadius: AppSpacing.borderRadiusMd),
        ),
      );
      return;
    }

    final notifier = ref.read(authStateNotifierProvider.notifier);
    await notifier.register(
      name: _nameController.text.trim(),
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
    // On success, GoRouter redirect handles navigation
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
                AppSpacing.vGap(AppSpacing.xl),
                // Header
                Text('Create account', style: AppTypography.h1),
                AppSpacing.vGap(AppSpacing.sm),
                Text(
                  'Start your digital discipline journey today.',
                  style: AppTypography.bodyMedium,
                ),
                AppSpacing.vGap(AppSpacing.huge),
                // Name
                MlTextField(
                  label: 'Full Name',
                  hint: 'Your name',
                  controller: _nameController,
                  keyboardType: TextInputType.name,
                  prefixIcon: Icons.person_outline_rounded,
                  focusNode: _nameFocus,
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) => _emailFocus.requestFocus(),
                  validator: _validateName,
                  enabled: !isLoading,
                ),
                AppSpacing.vGap(AppSpacing.lg),
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
                  label: 'Confirm Password',
                  hint: 'Repeat your password',
                  controller: _confirmPasswordController,
                  obscureText: true,
                  prefixIcon: Icons.lock_outline_rounded,
                  focusNode: _confirmPasswordFocus,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _onCreateAccount(),
                  validator: _validateConfirmPassword,
                  enabled: !isLoading,
                ),
                AppSpacing.vGap(AppSpacing.xl),
                // Terms checkbox
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: _agreedToTerms,
                        onChanged: isLoading
                            ? null
                            : (val) =>
                                setState(() => _agreedToTerms = val ?? false),
                        activeColor: AppColors.brandPrimary,
                        checkColor: AppColors.textPrimary,
                        side: const BorderSide(color: AppColors.border, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                        ),
                      ),
                    ),
                    AppSpacing.hGap(AppSpacing.md),
                    Expanded(
                      child: GestureDetector(
                        onTap: isLoading
                            ? null
                            : () => setState(() => _agreedToTerms = !_agreedToTerms),
                        child: RichText(
                          text: TextSpan(
                            text: 'I agree to the ',
                            style: AppTypography.bodyMedium,
                            children: [
                              TextSpan(
                                text: 'Terms of Service',
                                style: AppTypography.labelMedium.copyWith(
                                  color: AppColors.brandPrimary,
                                ),
                              ),
                              const TextSpan(text: ' and '),
                              TextSpan(
                                text: 'Privacy Policy',
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
                AppSpacing.vGap(AppSpacing.xxxl),
                // Create account button
                MlButton(
                  label: 'Create Account',
                  onPressed: isLoading ? null : _onCreateAccount,
                  isLoading: isLoading,
                  variant: MlButtonVariant.primary,
                  size: MlButtonSize.lg,
                ),
                AppSpacing.vGap(AppSpacing.xl),
                // Login link
                Center(
                  child: GestureDetector(
                    onTap: isLoading ? null : () => context.go(AppRoutes.login),
                    child: RichText(
                      text: TextSpan(
                        text: 'Already have an account? ',
                        style: AppTypography.bodyMedium,
                        children: [
                          TextSpan(
                            text: 'Login',
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
