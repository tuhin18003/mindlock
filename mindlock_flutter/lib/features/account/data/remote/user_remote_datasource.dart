import 'dart:io';
import 'package:dio/dio.dart';
import '../models/user_profile_model.dart';

class UserRemoteDatasource {
  final Dio _dio;

  UserRemoteDatasource(this._dio);

  /// GET /api/v1/user/
  Future<UserProfileModel> getProfile() async {
    final response = await _dio.get('/user/');
    return UserProfileModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// PUT /api/v1/user/
  Future<UserProfileModel> updateProfile({
    String? name,
    String? timezone,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (timezone != null) body['timezone'] = timezone;

    final response = await _dio.put('/user/', data: body);
    return UserProfileModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// PUT /api/v1/user/goals
  Future<void> updateGoals({
    int? dailyScreenLimitMinutes,
    int? dailyFocusGoalMinutes,
  }) async {
    final body = <String, dynamic>{};
    if (dailyScreenLimitMinutes != null) {
      body['daily_screen_limit_minutes'] = dailyScreenLimitMinutes;
    }
    if (dailyFocusGoalMinutes != null) {
      body['daily_focus_goal_minutes'] = dailyFocusGoalMinutes;
    }
    await _dio.put('/user/goals', data: body);
  }

  /// PUT /api/v1/user/notification-preferences
  Future<void> updateNotificationPreferences(
    Map<String, bool> preferences,
  ) async {
    await _dio.put('/user/notification-preferences', data: preferences);
  }

  /// POST /api/v1/user/avatar
  Future<String?> uploadAvatar(File imageFile) async {
    final formData = FormData.fromMap({
      'avatar': await MultipartFile.fromFile(
        imageFile.path,
        filename: 'avatar.jpg',
      ),
    });

    final response = await _dio.post(
      '/user/avatar',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );

    return response.data?['avatar'] as String?;
  }
}
