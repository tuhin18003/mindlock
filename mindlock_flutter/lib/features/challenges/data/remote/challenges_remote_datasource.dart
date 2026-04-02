import 'package:dio/dio.dart';
import '../models/challenge_model.dart';

class ChallengesRemoteDatasource {
  final Dio _dio;

  ChallengesRemoteDatasource(this._dio);

  /// GET /api/v1/challenges
  Future<List<ChallengeModel>> getChallenges({
    String? category,
    bool? isPro,
  }) async {
    final queryParams = <String, dynamic>{};
    if (category != null) queryParams['category'] = category;
    if (isPro != null) queryParams['is_pro'] = isPro;

    final response = await _dio.get(
      '/challenges',
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    final data = response.data;
    final list = data is List ? data : (data['data'] as List? ?? []);
    return list
        .cast<Map<String, dynamic>>()
        .map(ChallengeModel.fromJson)
        .toList();
  }

  /// GET /api/v1/challenges/for-intervention?package={packageName}
  Future<List<ChallengeModel>> getForIntervention({
    required String packageName,
  }) async {
    final response = await _dio.get(
      '/challenges/for-intervention',
      queryParameters: {'package': packageName},
    );

    final data = response.data;
    final list = data is List ? data : (data['data'] as List? ?? []);
    return list
        .cast<Map<String, dynamic>>()
        .map(ChallengeModel.fromJson)
        .toList();
  }

  /// GET /api/v1/challenges/{id}
  Future<ChallengeModel> getChallenge(int id) async {
    final response = await _dio.get('/challenges/$id');
    return ChallengeModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// POST /api/v1/sync/challenge-completions
  /// Submits the result of a completed challenge to the backend.
  Future<void> submitCompletion({
    required String localEventId,
    required int challengeId,
    required String result, // 'completed', 'failed', 'skipped'
    String? packageName,
    int? rewardGrantedMinutes,
  }) async {
    await _dio.post('/sync/challenge-completions', data: {
      'completions': [
        {
          'local_event_id': localEventId,
          'challenge_id': challengeId,
          'result': result,
          if (packageName != null) 'package_name': packageName,
          if (rewardGrantedMinutes != null)
            'reward_granted_minutes': rewardGrantedMinutes,
          'completed_at': DateTime.now().toUtc().toIso8601String(),
        }
      ],
    });
  }
}
