import 'package:dio/dio.dart';
import 'models/auth_response_model.dart';

class AuthRemoteDatasource {
  final Dio _dio;

  AuthRemoteDatasource(this._dio);

  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post(
      '/auth/login',
      data: {
        'email': email,
        'password': password,
      },
    );
    return AuthResponse.fromJson(response.data as Map<String, dynamic>);
  }

  Future<AuthResponse> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await _dio.post(
      '/auth/register',
      data: {
        'name': name,
        'email': email,
        'password': password,
      },
    );
    return AuthResponse.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> logout(String token) async {
    await _dio.post(
      '/auth/logout',
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
      ),
    );
  }

  Future<UserModel> me(String token) async {
    final response = await _dio.get(
      '/auth/me',
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
      ),
    );
    final data = response.data as Map<String, dynamic>;
    final userData = data['data'] as Map<String, dynamic>? ?? data;
    return UserModel.fromJson(userData);
  }

  Future<void> forgotPassword({required String email}) async {
    await _dio.post(
      '/auth/forgot-password',
      data: {'email': email},
    );
  }

  Future<void> resetPassword({
    required String token,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    await _dio.post(
      '/auth/reset-password',
      data: {
        'token': token,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
      },
    );
  }
}
