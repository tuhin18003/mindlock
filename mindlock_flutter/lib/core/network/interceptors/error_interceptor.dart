import 'package:dio/dio.dart';
import '../../errors/exceptions.dart';

class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        throw NetworkException(message: 'Request timed out');

      case DioExceptionType.connectionError:
        throw const NetworkException();

      case DioExceptionType.badResponse:
        final statusCode = err.response?.statusCode;
        final data = err.response?.data;

        if (statusCode == 401) {
          throw const UnauthorizedException();
        }

        if (statusCode == 422) {
          final message = data?['message'] ?? 'Validation failed';
          final errors = _parseValidationErrors(data?['errors']);
          throw ValidationException(message: message, errors: errors);
        }

        final message = data?['message'] ?? 'Server error occurred';
        throw ServerException(message: message, statusCode: statusCode);

      default:
        throw ServerException(
          message: err.message ?? 'An unexpected error occurred',
        );
    }
  }

  Map<String, List<String>>? _parseValidationErrors(dynamic errors) {
    if (errors == null || errors is! Map) return null;
    return errors.map(
      (key, value) => MapEntry(
        key.toString(),
        (value as List).map((e) => e.toString()).toList(),
      ),
    );
  }
}
