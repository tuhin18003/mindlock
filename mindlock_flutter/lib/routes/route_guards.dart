import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/presentation/providers/auth_provider.dart';
import '../core/constants/storage_keys.dart';
import 'app_routes.dart';

class RouteGuards {
  final Ref _ref;
  RouteGuards(this._ref);

  Future<String?> redirect(_, GoRouterState state) async {
    final authState = _ref.read(authStateProvider);
    final isAuthenticated = authState.isAuthenticated;
    final isOnboardingComplete = authState.isOnboardingComplete;

    final location = state.matchedLocation;

    final authRoutes = [
      AppRoutes.login,
      AppRoutes.register,
      AppRoutes.forgotPassword,
      AppRoutes.resetPassword,
      AppRoutes.welcome,
      AppRoutes.splash,
    ];

    // Splash — always allow, let splash screen handle init
    if (location == AppRoutes.splash) return null;

    // Not authenticated → send to welcome/login
    if (!isAuthenticated) {
      if (authRoutes.contains(location)) return null;
      return AppRoutes.welcome;
    }

    // Authenticated but onboarding not complete → send to onboarding
    if (!isOnboardingComplete && location != AppRoutes.onboarding) {
      return AppRoutes.onboarding;
    }

    // Authenticated + onboarding complete, trying to visit auth route
    if (isAuthenticated && authRoutes.contains(location)) {
      return AppRoutes.dashboard;
    }

    return null;
  }
}
