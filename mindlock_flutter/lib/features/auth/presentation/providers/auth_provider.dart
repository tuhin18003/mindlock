import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../../services/storage/prefs_service.dart';
import '../../../../core/constants/app_constants.dart';
import 'auth_repository_provider.dart';

part 'auth_provider.freezed.dart';
part 'auth_provider.g.dart';

@freezed
class AuthState with _$AuthState {
  const factory AuthState({
    @Default(false) bool isAuthenticated,
    @Default(false) bool isOnboardingComplete,
    @Default(false) bool isLoading,
    @Default(false) bool isInitialized,
    String? userId,
    String? userName,
    String? userEmail,
    String? userAvatar,
    String? error,
  }) = _AuthState;
}

@riverpod
class AuthStateNotifier extends _$AuthStateNotifier {
  @override
  AuthState build() => const AuthState();

  /// Called by SplashScreen on startup — checks stored token and restores session.
  Future<void> initialize() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final repository = ref.read(authRepositoryProvider);
      final token = await repository.getStoredToken();

      if (token == null || token.isEmpty) {
        // No token — check onboarding flag then mark initialized
        final onboardingDone = await _getOnboardingFlag();
        state = state.copyWith(
          isAuthenticated: false,
          isOnboardingComplete: onboardingDone,
          isLoading: false,
          isInitialized: true,
        );
        return;
      }

      // Token exists — verify with /me
      final result = await repository.getMe();
      if (result.success && result.data != null) {
        final user = result.data!;
        final onboardingDone = await _getOnboardingFlag();
        state = state.copyWith(
          isAuthenticated: true,
          isOnboardingComplete: onboardingDone,
          isLoading: false,
          isInitialized: true,
          userId: user.id,
          userName: user.name,
          userEmail: user.email,
          userAvatar: user.avatar,
          error: null,
        );
      } else {
        // Token invalid — clear and go unauthenticated
        final onboardingDone = await _getOnboardingFlag();
        state = state.copyWith(
          isAuthenticated: false,
          isOnboardingComplete: onboardingDone,
          isLoading: false,
          isInitialized: true,
          error: null,
        );
      }
    } catch (_) {
      state = state.copyWith(
        isAuthenticated: false,
        isLoading: false,
        isInitialized: true,
      );
    }
  }

  Future<void> login({required String email, required String password}) async {
    state = state.copyWith(isLoading: true, error: null);

    final repository = ref.read(authRepositoryProvider);
    final result = await repository.login(email: email, password: password);

    if (result.success && result.data != null) {
      final response = result.data!;
      final onboardingDone = await _getOnboardingFlag();
      state = state.copyWith(
        isAuthenticated: true,
        isOnboardingComplete: onboardingDone,
        isLoading: false,
        userId: response.user.id,
        userName: response.user.name,
        userEmail: response.user.email,
        userAvatar: response.user.avatar,
        error: null,
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        error: result.error ?? 'Login failed',
      );
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    final repository = ref.read(authRepositoryProvider);
    final result = await repository.register(
      name: name,
      email: email,
      password: password,
    );

    if (result.success && result.data != null) {
      final response = result.data!;
      state = state.copyWith(
        isAuthenticated: true,
        isOnboardingComplete: false,
        isLoading: false,
        userId: response.user.id,
        userName: response.user.name,
        userEmail: response.user.email,
        userAvatar: response.user.avatar,
        error: null,
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        error: result.error ?? 'Registration failed',
      );
    }
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true, error: null);

    final repository = ref.read(authRepositoryProvider);
    await repository.logout();

    // Clear onboarding flag too on full logout
    try {
      final prefsAsync = await ref.read(prefsServiceProvider.future);
      await prefsAsync.remove(AppConstants.onboardingCompleteKey);
    } catch (_) {}

    state = const AuthState(isInitialized: true);
  }

  Future<void> forgotPassword({required String email}) async {
    state = state.copyWith(isLoading: true, error: null);

    final repository = ref.read(authRepositoryProvider);
    final result = await repository.forgotPassword(email: email);

    state = state.copyWith(
      isLoading: false,
      error: result.success ? null : (result.error ?? 'Request failed'),
    );
  }

  Future<void> resetPassword({
    required String token,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    final repository = ref.read(authRepositoryProvider);
    final result = await repository.resetPassword(
      token: token,
      email: email,
      password: password,
      passwordConfirmation: passwordConfirmation,
    );

    state = state.copyWith(
      isLoading: false,
      error: result.success ? null : (result.error ?? 'Reset failed'),
    );
  }

  void setOnboardingComplete() {
    state = state.copyWith(isOnboardingComplete: true);
  }

  void setAuthenticated({
    required bool authenticated,
    String? userId,
    bool onboardingComplete = false,
  }) {
    state = state.copyWith(
      isAuthenticated: authenticated,
      userId: userId,
      isOnboardingComplete: onboardingComplete,
    );
  }

  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }

  void setError(String? error) {
    state = state.copyWith(error: error, isLoading: false);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  Future<bool> _getOnboardingFlag() async {
    try {
      final prefsAsync = await ref.read(prefsServiceProvider.future);
      return prefsAsync.getBool(AppConstants.onboardingCompleteKey) ?? false;
    } catch (_) {
      return false;
    }
  }
}

// Convenience read-only provider
@riverpod
AuthState authState(Ref ref) {
  return ref.watch(authStateNotifierProvider);
}
