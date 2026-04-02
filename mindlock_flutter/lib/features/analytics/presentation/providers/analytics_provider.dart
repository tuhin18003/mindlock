import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/local/database/app_database.dart';
import '../../../../data/local/database/database_provider.dart';
import '../../data/models/analytics_models.dart';

/// Selected date range period in days (7, 30, or 90).
final analyticsPeriodProvider = StateProvider<int>((ref) => 30);

/// Computes analytics from the local Drift database.
/// Reads usage_logs, lock_events, and challenge_completions tables.
final analyticsProvider = FutureProvider<AnalyticsSummary>((ref) async {
  final periodDays = ref.watch(analyticsPeriodProvider);
  final db = ref.watch(appDatabaseProvider);
  return _computeFromDb(db, periodDays);
});

Future<AnalyticsSummary> _computeFromDb(AppDatabase db, int periodDays) async {
  final now = DateTime.now();
  final effectiveDays = periodDays > 30 ? 30 : periodDays;

  // Build daily trend from local usage_logs
  final List<UsageTrendPoint> trend = [];
  final Map<String, int> appMinutesMap = {};
  final Map<String, int> appLockCountMap = {};
  int totalLocks = 0;

  for (int i = effectiveDays - 1; i >= 0; i--) {
    final date = now.subtract(Duration(days: i));
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    final logs = await db.usageLogsDao.getLogsForDate(dateStr);
    final dayScreenMinutes =
        logs.fold<int>(0, (sum, l) => sum + (l.usageSeconds ~/ 60));

    trend.add(UsageTrendPoint(
      date: dateStr,
      screenMinutes: dayScreenMinutes,
      recoveredMinutes: 0, // unlock rewards not stored per-day in local DB yet
    ));

    // Accumulate per-app totals
    for (final log in logs) {
      appMinutesMap[log.packageName] =
          (appMinutesMap[log.packageName] ?? 0) + (log.usageSeconds ~/ 60);
    }
  }

  // Get lock counts per app from lock_events
  final unsyncedLocks = await db.lockEventsDao.getUnsynced();
  totalLocks = unsyncedLocks.length;
  for (final event in unsyncedLocks) {
    final cutoff = now.subtract(Duration(days: effectiveDays));
    if (event.lockedAt.isAfter(cutoff)) {
      appLockCountMap[event.packageName] =
          (appLockCountMap[event.packageName] ?? 0) + 1;
    }
  }

  // Build top apps list sorted by screen time
  final topApps = appMinutesMap.entries
      .map((e) => AppUsageStat(
            packageName: e.key,
            appName: _appNameFromPackage(e.key),
            totalMinutes: e.value,
            lockCount: appLockCountMap[e.key] ?? 0,
          ))
      .toList()
    ..sort((a, b) => b.totalMinutes.compareTo(a.totalMinutes));

  final totalScreenMinutes = trend.fold<int>(0, (s, p) => s + p.screenMinutes);
  final avgDaily =
      trend.isNotEmpty ? totalScreenMinutes / trend.length : 0.0;

  return AnalyticsSummary(
    screenTimeTrend: trend,
    topApps: topApps.take(10).toList(),
    avgDailyScreenMinutes: avgDaily,
    totalLocks30d: totalLocks,
    challengeSuccessRate: 0, // Extended via backend analytics API in future
    recoveryScoreAvg: 0,
  );
}

String _appNameFromPackage(String packageName) {
  const knownApps = {
    'com.instagram.android': 'Instagram',
    'com.zhiliaoapp.musically': 'TikTok',
    'com.twitter.android': 'X (Twitter)',
    'com.facebook.katana': 'Facebook',
    'com.reddit.frontpage': 'Reddit',
    'com.youtube.android': 'YouTube',
    'com.snapchat.android': 'Snapchat',
    'com.whatsapp': 'WhatsApp',
    'com.linkedin.android': 'LinkedIn',
    'com.pinterest': 'Pinterest',
  };
  return knownApps[packageName] ??
      packageName.split('.').last.replaceAll('_', ' ');
}
