import 'package:dio/dio.dart';
import '../models/app_device_config_model.dart';
import '../models/monitored_app_model.dart';

class AppsRemoteDatasource {
  final Dio _dio;
  final String _token;

  AppsRemoteDatasource({required Dio dio, required String token})
      : _dio = dio,
        _token = token;

  Map<String, String> get _headers => {
        'Authorization': 'Bearer $_token',
        'Accept': 'application/json',
      };

  /// GET /api/v1/apps/config
  Future<AppDeviceConfig> getDeviceConfig() async {
    final response = await _dio.get(
      '/apps/config',
      options: Options(headers: _headers),
    );
    return AppDeviceConfig.fromJson(response.data as Map<String, dynamic>);
  }

  /// PUT /api/v1/apps/{packageName}/limit
  Future<void> setLimit(
    String packageName, {
    int? dailyLimitMinutes,
    int? weekdayLimitMinutes,
    int? weekendLimitMinutes,
  }) async {
    await _dio.put(
      '/apps/$packageName/limit',
      data: {
        if (dailyLimitMinutes != null) 'daily_limit_minutes': dailyLimitMinutes,
        if (weekdayLimitMinutes != null) 'weekday_limit_minutes': weekdayLimitMinutes,
        if (weekendLimitMinutes != null) 'weekend_limit_minutes': weekendLimitMinutes,
      },
      options: Options(headers: _headers),
    );
  }

  /// DELETE /api/v1/apps/{packageName}/limit
  Future<void> removeLimit(String packageName) async {
    await _dio.delete(
      '/apps/$packageName/limit',
      options: Options(headers: _headers),
    );
  }

  /// PUT /api/v1/apps/{packageName}/lock
  Future<void> toggleLock(
    String packageName, {
    required bool isLocked,
    required String lockMode,
  }) async {
    await _dio.put(
      '/apps/$packageName/lock',
      data: {
        'is_locked': isLocked,
        'lock_mode': lockMode,
      },
      options: Options(headers: _headers),
    );
  }

  /// GET /api/v1/apps/
  Future<List<MonitoredAppModel>> getInstalledApps() async {
    final response = await _dio.get(
      '/apps/',
      options: Options(headers: _headers),
    );
    final data = response.data as List<dynamic>? ?? [];
    return data
        .map((e) => MonitoredAppModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
