import 'package:dio/dio.dart';
import '../models/history_models.dart';

class HistoryRemoteDatasource {
  final Dio _dio;
  final String _token;

  HistoryRemoteDatasource({required Dio dio, required String token})
      : _dio = dio,
        _token = token;

  Map<String, String> get _headers => {
        'Authorization': 'Bearer $_token',
        'Accept': 'application/json',
      };

  /// GET /api/v1/history/activity
  Future<List<ActivityEvent>> getActivity({
    int limit = 20,
    String? before,
  }) async {
    final response = await _dio.get(
      '/history/activity',
      queryParameters: {
        'limit': limit,
        if (before != null) 'before': before,
      },
      options: Options(headers: _headers),
    );
    final data = response.data as List<dynamic>? ?? [];
    return data
        .map((e) => ActivityEvent.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /api/v1/history/stats
  Future<HistoryStats> getStats({int days = 30}) async {
    final response = await _dio.get(
      '/history/stats',
      queryParameters: {'days': days},
      options: Options(headers: _headers),
    );
    return HistoryStats.fromJson(response.data as Map<String, dynamic>);
  }

  /// GET /api/v1/history/locks
  Future<List<ActivityEvent>> getLocks({
    String? from,
    String? to,
  }) async {
    final response = await _dio.get(
      '/history/locks',
      queryParameters: {
        if (from != null) 'from': from,
        if (to != null) 'to': to,
      },
      options: Options(headers: _headers),
    );
    final data = response.data as List<dynamic>? ?? [];
    return data
        .map((e) => ActivityEvent.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /api/v1/history/challenges
  Future<List<ActivityEvent>> getChallenges({
    String? from,
    String? to,
  }) async {
    final response = await _dio.get(
      '/history/challenges',
      queryParameters: {
        if (from != null) 'from': from,
        if (to != null) 'to': to,
      },
      options: Options(headers: _headers),
    );
    final data = response.data as List<dynamic>? ?? [];
    return data
        .map((e) => ActivityEvent.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
