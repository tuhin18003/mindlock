import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/local/database/database_provider.dart';
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
  final db = ref.read(appDatabaseProvider);
  final today = DateTime.now();

  String dateStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  final todayStr = dateStr(today);
  final summary = await tracker.getDailySummary(todayStr);

  // Build real 7-day weekly trend from local usage_logs
  final List<WeeklyDataPoint> weeklyTrend = [];
  for (int i = 6; i >= 0; i--) {
    final d = today.subtract(Duration(days: i));
    final ds = dateStr(d);
    final logs = await db.usageLogsDao.getLogsForDate(ds);
    final screenSeconds = logs.fold<int>(0, (s, l) => s + l.usageSeconds);
    weeklyTrend.add(WeeklyDataPoint(
      date: ds,
      screenSeconds: screenSeconds,
      recoveredMinutes: 0, // enhanced when unlock events are synced
    ));
  }

  // Count today's lock events from local DB
  final todayLocks = await db.lockEventsDao.getUnsynced();
  final lockCountToday = todayLocks
      .where((e) => dateStr(e.lockedAt) == todayStr)
      .length;

  return DashboardSummary(
    screenTimeSeconds: summary.totalScreenSeconds,
    recoveredMinutes: 0,
    lockCount: lockCountToday,
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
