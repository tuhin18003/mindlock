import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../services/tracking/usage_tracker_service.dart';

part 'dashboard_provider.freezed.dart';
part 'dashboard_provider.g.dart';

@freezed
class DashboardSummary with _$DashboardSummary {
  const factory DashboardSummary({
    required int screenTimeSeconds,
    required int recoveredMinutes,
    required int lockCount,
    required int focusMinutes,
    required int recoveryScore,
    required int currentStreak,
    required int challengeCompletionsToday,
    required int emergencyUnlocksToday,
    required bool isProUser,
    String? topDistractionApp,
    @Default(0) int topDistractionSeconds,
    String? behaviorInsight,
    @Default([]) List<WeeklyDataPoint> weeklyTrend,
  }) = _DashboardSummary;
}

@freezed
class WeeklyDataPoint with _$WeeklyDataPoint {
  const factory WeeklyDataPoint({
    required String date,
    required int screenSeconds,
    required int recoveredMinutes,
  }) = _WeeklyDataPoint;
}

@riverpod
Future<DashboardSummary> dashboardSummary(Ref ref) async {
  final tracker = ref.read(usageTrackerServiceProvider);
  final today = DateTime.now();
  final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

  final summary = await tracker.getDailySummary(todayStr);

  // Generate last 7 days trend (placeholder data for now)
  final weeklyTrend = List.generate(7, (i) {
    final d = today.subtract(Duration(days: 6 - i));
    return WeeklyDataPoint(
      date: '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}',
      screenSeconds: 0,
      recoveredMinutes: 0,
    );
  });

  return DashboardSummary(
    screenTimeSeconds: summary.totalScreenSeconds,
    recoveredMinutes: 0,
    lockCount: 0,
    focusMinutes: 0,
    recoveryScore: 0,
    currentStreak: 0,
    challengeCompletionsToday: 0,
    emergencyUnlocksToday: 0,
    isProUser: false,
    topDistractionApp: summary.topDistraction,
    weeklyTrend: weeklyTrend,
    behaviorInsight: _generateInsight(summary.totalScreenSeconds),
  );
}

String _generateInsight(int screenSeconds) {
  final hours = screenSeconds / 3600;
  if (hours < 2) return 'Great discipline today. Keep it up.';
  if (hours < 4) return 'You protected meaningful attention today.';
  if (hours < 6) return 'Heavy screen day. Tomorrow is a fresh start.';
  return 'Your attention is worth protecting. Let\'s build better habits.';
}
