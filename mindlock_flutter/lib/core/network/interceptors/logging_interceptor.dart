import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

class LoggingInterceptor extends Interceptor {
  final _logger = Logger(
    printer: PrettyPrinter(methodCount: 0, noBoxingByDefault: true),
  );

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _logger.d('[API] → ${options.method} ${options.path}');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _logger.d('[API] ← ${response.statusCode} ${response.requestOptions.path}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _logger.e(
      '[API] ✗ ${err.response?.statusCode ?? "?"} ${err.requestOptions.path}: ${err.message}',
    );
    handler.next(err);
  }
}
