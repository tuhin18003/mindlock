import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../data/models/user_profile_model.dart';
import '../../data/remote/user_remote_datasource.dart';

class ProfileState {
  final UserProfileModel? user;
  final bool isLoading;
  final bool isSaving;
  final String? error;

  const ProfileState({
    this.user,
    this.isLoading = false,
    this.isSaving = false,
    this.error,
  });

  ProfileState copyWith({
    UserProfileModel? user,
    bool? isLoading,
    bool? isSaving,
    String? error,
    bool clearError = false,
  }) {
    return ProfileState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class ProfileNotifier extends StateNotifier<ProfileState> {
  final UserRemoteDatasource _datasource;

  ProfileNotifier(this._datasource) : super(const ProfileState());

  Future<void> loadProfile() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _datasource.getProfile();
      state = state.copyWith(user: user, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load profile: ${e.toString()}',
      );
    }
  }

  Future<void> updateProfile({String? name, String? timezone}) async {
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      final updated = await _datasource.updateProfile(
        name: name,
        timezone: timezone,
      );
      state = state.copyWith(user: updated, isSaving: false);
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        error: 'Failed to save profile: ${e.toString()}',
      );
    }
  }

  Future<void> updateAvatar(File imageFile) async {
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      final avatarUrl = await _datasource.uploadAvatar(imageFile);
      if (avatarUrl != null && state.user != null) {
        state = state.copyWith(
          user: state.user!.copyWith(avatar: avatarUrl),
          isSaving: false,
        );
      } else {
        state = state.copyWith(isSaving: false);
      }
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        error: 'Failed to upload avatar: ${e.toString()}',
      );
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

final _userRemoteDatasourceProvider = Provider<UserRemoteDatasource>((ref) {
  final dio = ref.watch(dioProvider);
  return UserRemoteDatasource(dio);
});

final profileProvider = StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
  final datasource = ref.watch(_userRemoteDatasourceProvider);
  return ProfileNotifier(datasource);
});
