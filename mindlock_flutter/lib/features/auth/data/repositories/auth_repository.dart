import 'package:dio/dio.dart';
import '../../../../services/storage/secure_storage_service.dart';
import '../../../../core/constants/app_constants.dart';
import '../remote/auth_remote_datasource.dart';
import '../remote/models/auth_response_model.dart';

class AuthRepositoryResult<T> {
  final T? data;
  final String? error;
  final bool success;

  const AuthRepositoryResult.success(this.data)
      : error = null,
        success = true;

  const AuthRepositoryResult.failure(this.error)
      : data = null,
        success = false;
}

class AuthRepository {
  final AuthRemoteDatasource _datasource;
  final SecureStorageService _storage;

  AuthRepository({
    required AuthRemoteDatasource datasource,
    required SecureStorageService storage,
  })  : _datasource = datasource,
        _storage = storage;

  Future<AuthRepositoryResult<AuthResponse>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _datasource.login(email: email, password: password);
      await _storage.write(AppConstants.accessTokenKey, response.token);
      await _storage.write(AppConstants.userIdKey, response.user.id);
      return AuthRepositoryResult.success(response);
    } on DioException catch (e) {
      return AuthRepositoryResult.failure(_extractErrorMessage(e));
    } catch (e) {
      return AuthRepositoryResult.failure(e.toString());
    }
  }

  Future<AuthRepositoryResult<AuthResponse>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _datasource.register(
        name: name,
        email: email,
        password: password,
      );
      await _storage.write(AppConstants.accessTokenKey, response.token);
      await _storage.write(AppConstants.userIdKey, response.user.id);
      return AuthRepositoryResult.success(response);
    } on DioException catch (e) {
      return AuthRepositoryResult.failure(_extractErrorMessage(e));
    } catch (e) {
      return AuthRepositoryResult.failure(e.toString());
    }
  }

  Future<AuthRepositoryResult<void>> logout() async {
    try {
      final token = await _storage.read(AppConstants.accessTokenKey);
      if (token != null) {
        await _datasource.logout(token);
      }
      await _storage.deleteAll();
      return const AuthRepositoryResult.success(null);
    } on DioException catch (e) {
      // Even on API error, clear local storage
      await _storage.deleteAll();
      return AuthRepositoryResult.failure(_extractErrorMessage(e));
    } catch (e) {
      await _storage.deleteAll();
      return AuthRepositoryResult.failure(e.toString());
    }
  }

  Future<AuthRepositoryResult<UserModel>> getMe() async {
    try {
      final token = await _storage.read(AppConstants.accessTokenKey);
      if (token == null) {
        return const AuthRepositoryResult.failure('No token stored');
      }
      final user = await _datasource.me(token);
      return AuthRepositoryResult.success(user);
    } on DioException catch (e) {
      return AuthRepositoryResult.failure(_extractErrorMessage(e));
    } catch (e) {
      return AuthRepositoryResult.failure(e.toString());
    }
  }

  Future<AuthRepositoryResult<void>> forgotPassword({required String email}) async {
    try {
      await _datasource.forgotPassword(email: email);
      return const AuthRepositoryResult.success(null);
    } on DioException catch (e) {
      return AuthRepositoryResult.failure(_extractErrorMessage(e));
    } catch (e) {
      return AuthRepositoryResult.failure(e.toString());
    }
  }

  Future<AuthRepositoryResult<void>> resetPassword({
    required String token,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      await _datasource.resetPassword(
        token: token,
        email: email,
        password: password,
        passwordConfirmation: passwordConfirmation,
      );
      return const AuthRepositoryResult.success(null);
    } on DioException catch (e) {
      return AuthRepositoryResult.failure(_extractErrorMessage(e));
    } catch (e) {
      return AuthRepositoryResult.failure(e.toString());
    }
  }

  Future<String?> getStoredToken() async {
    return _storage.read(AppConstants.accessTokenKey);
  }

  String _extractErrorMessage(DioException e) {
    try {
      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        if (data['message'] != null) return data['message'] as String;
        if (data['error'] != null) return data['error'] as String;
        // Laravel validation errors
        final errors = data['errors'] as Map<String, dynamic>?;
        if (errors != null && errors.isNotEmpty) {
          final firstField = errors.values.first;
          if (firstField is List && firstField.isNotEmpty) {
            return firstField.first.toString();
          }
        }
      }
    } catch (_) {}
    return e.message ?? 'An unexpected error occurred';
  }
}
