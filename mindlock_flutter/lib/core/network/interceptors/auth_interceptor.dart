import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../constants/storage_keys.dart';
import '../../../services/storage/secure_storage_service.dart';

part 'auth_interceptor.g.dart';

@riverpod
AuthInterceptor authInterceptor(Ref ref) {
  return AuthInterceptor(ref.read(secureStorageServiceProvider));
}

class AuthInterceptor extends Interceptor {
  final SecureStorageService _storage;

  AuthInterceptor(this._storage);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.read(StorageKeys.accessToken);
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      // Token expired — auth state notifier will handle sign-out
      // Emit event via a stream/notifier if needed
    }
    handler.next(err);
  }
}
