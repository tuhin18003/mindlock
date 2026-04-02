import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/theme/app_spacing.dart';
import '../features/auth/presentation/providers/auth_provider.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/register_screen.dart';
import '../features/auth/presentation/screens/forgot_password_screen.dart';
import '../features/auth/presentation/screens/reset_password_screen.dart';
import '../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../features/dashboard/presentation/screens/home_shell.dart';
import '../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../features/apps/presentation/screens/apps_screen.dart';
import '../features/history/presentation/screens/history_screen.dart';
import '../features/settings/presentation/screens/settings_screen.dart';
import '../features/subscription/presentation/screens/paywall_screen.dart';
import '../features/locks/presentation/screens/lock_screen.dart';
import '../features/challenges/presentation/screens/challenge_screen.dart';
import '../features/account/presentation/screens/profile_screen.dart';
import '../features/analytics/presentation/screens/analytics_screen.dart';
import 'route_guards.dart';

part 'app_routes.g.dart';

class AppRoutes {
  // Auth
  static const String splash = '/';
  static const String welcome = '/welcome';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';

  // Onboarding
  static const String onboarding = '/onboarding';

  // Main shell
  static const String home = '/home';
  static const String dashboard = '/home/dashboard';
  static const String apps = '/home/apps';
  static const String history = '/home/history';
  static const String settings = '/home/settings';

  // Feature
  static const String lock = '/lock';
  static const String challenge = '/challenge';
  static const String paywall = '/paywall';
  static const String profile = '/profile';
  static const String analytics = '/analytics';
}

@riverpod
GoRouter appRouter(Ref ref) {
  final guards = RouteGuards(ref);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    redirect: guards.redirect,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: AppRoutes.welcome,
        builder: (context, state) => const WelcomePage(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.resetPassword,
        builder: (context, state) => ResetPasswordScreen(
          token: state.uri.queryParameters['token'] ?? '',
        ),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.paywall,
        builder: (context, state) => const PaywallScreen(),
      ),
      GoRoute(
        path: AppRoutes.lock,
        builder: (context, state) => LockScreen(
          packageName: state.uri.queryParameters['package'] ?? '',
        ),
      ),
      GoRoute(
        path: AppRoutes.challenge,
        builder: (context, state) => ChallengeScreen(
          challengeId: state.uri.queryParameters['id'] ?? '',
          packageName: state.uri.queryParameters['package'],
        ),
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.analytics,
        builder: (context, state) => const AnalyticsScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => HomeShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.dashboard,
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: AppRoutes.apps,
            builder: (context, state) => const AppsScreen(),
          ),
          GoRoute(
            path: AppRoutes.history,
            builder: (context, state) => const HistoryScreen(),
          ),
          GoRoute(
            path: AppRoutes.settings,
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
    ],
  );
}

// ---------------------------------------------------------------------------
// Splash Page
// ---------------------------------------------------------------------------

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _scaleAnim = Tween<double>(begin: 0.75, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );
    _animController.forward();
    _init();
  }

  Future<void> _init() async {
    // Run init and wait at least 2 seconds for a polished splash
    await Future.wait([
      ref.read(authStateNotifierProvider.notifier).initialize(),
      Future.delayed(const Duration(milliseconds: 2000)),
    ]);
    // GoRouter redirect will take over based on authState
    if (mounted) {
      context.go(AppRoutes.welcome);
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: ScaleTransition(
            scale: _scaleAnim,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // App icon container
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    gradient: AppColors.brandGradient,
                    borderRadius: AppSpacing.borderRadiusXl,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.brandPrimary.withOpacity(0.4),
                        blurRadius: 32,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.lock_outline_rounded,
                    size: 48,
                    color: AppColors.textPrimary,
                  ),
                ),
                AppSpacing.vGap(AppSpacing.xxl),
                Text(
                  'MindLock',
                  style: AppTypography.displayMedium,
                ),
                AppSpacing.vGap(AppSpacing.sm),
                Text(
                  'Reclaim your focus.',
                  style: AppTypography.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Welcome Page
// ---------------------------------------------------------------------------

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xxl,
            vertical: AppSpacing.xxxl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              // Logo
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  gradient: AppColors.brandGradient,
                  borderRadius: AppSpacing.borderRadiusXl,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.brandPrimary.withOpacity(0.35),
                      blurRadius: 28,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.lock_outline_rounded,
                  size: 44,
                  color: AppColors.textPrimary,
                ),
              ),
              AppSpacing.vGap(AppSpacing.xxl),
              Text(
                'MindLock',
                style: AppTypography.displayMedium,
                textAlign: TextAlign.center,
              ),
              AppSpacing.vGap(AppSpacing.md),
              Text(
                'Reclaim your focus.',
                style: AppTypography.h3.copyWith(
                  color: AppColors.brandPrimary,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              AppSpacing.vGap(AppSpacing.lg),
              Text(
                'Take back your attention.\nBuild real discipline, one day at a time.',
                style: AppTypography.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const Spacer(flex: 3),
              // CTA buttons
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => context.go(AppRoutes.register),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandPrimary,
                    foregroundColor: AppColors.textPrimary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: AppSpacing.borderRadiusMd,
                    ),
                  ),
                  child: Text('Get Started', style: AppTypography.button),
                ),
              ),
              AppSpacing.vGap(AppSpacing.md),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: () => context.go(AppRoutes.login),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppSpacing.borderRadiusMd,
                    ),
                  ),
                  child: Text(
                    'I have an account',
                    style: AppTypography.button.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
              AppSpacing.vGap(AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }
}
