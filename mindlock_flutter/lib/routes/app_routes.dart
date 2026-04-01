import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
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

// Temporary placeholder screens
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(
    body: Center(child: CircularProgressIndicator()),
  );
}

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(
    body: Center(child: Text('Welcome to MindLock')),
  );
}
