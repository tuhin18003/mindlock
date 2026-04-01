import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_provider.freezed.dart';
part 'auth_provider.g.dart';

@freezed
class AuthState with _$AuthState {
  const factory AuthState({
    @Default(false) bool isAuthenticated,
    @Default(false) bool isOnboardingComplete,
    @Default(false) bool isLoading,
    String? userId,
    String? error,
  }) = _AuthState;
}

@riverpod
class AuthStateNotifier extends _$AuthStateNotifier {
  @override
  AuthState build() => const AuthState();

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

  void setOnboardingComplete() {
    state = state.copyWith(isOnboardingComplete: true);
  }

  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }

  void setError(String? error) {
    state = state.copyWith(error: error, isLoading: false);
  }

  void logout() {
    state = const AuthState();
  }
}

// Convenience read-only provider
@riverpod
AuthState authState(Ref ref) {
  return ref.watch(authStateNotifierProvider);
}
