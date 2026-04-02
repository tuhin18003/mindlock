class UsageTrendPoint {
  final String date;
  final int screenMinutes;
  final int recoveredMinutes;

  const UsageTrendPoint({
    required this.date,
    required this.screenMinutes,
    required this.recoveredMinutes,
  });

  factory UsageTrendPoint.fromJson(Map<String, dynamic> json) {
    return UsageTrendPoint(
      date: json['date'] as String,
      screenMinutes: (json['screen_minutes'] as num?)?.toInt() ?? 0,
      recoveredMinutes: (json['recovered_minutes'] as num?)?.toInt() ?? 0,
    );
  }
}

class AppUsageStat {
  final String packageName;
  final String appName;
  final int totalMinutes;
  final int lockCount;

  const AppUsageStat({
    required this.packageName,
    required this.appName,
    required this.totalMinutes,
    required this.lockCount,
  });

  factory AppUsageStat.fromJson(Map<String, dynamic> json) {
    return AppUsageStat(
      packageName: json['package_name'] as String,
      appName: json['app_name'] as String,
      totalMinutes: (json['total_minutes'] as num?)?.toInt() ?? 0,
      lockCount: (json['lock_count'] as num?)?.toInt() ?? 0,
    );
  }
}

class AnalyticsSummary {
  final List<UsageTrendPoint> screenTimeTrend; // 7 or 30 days
  final List<AppUsageStat> topApps;
  final double avgDailyScreenMinutes;
  final int totalLocks30d;
  final int challengeSuccessRate;
  final int recoveryScoreAvg;

  const AnalyticsSummary({
    required this.screenTimeTrend,
    required this.topApps,
    required this.avgDailyScreenMinutes,
    required this.totalLocks30d,
    required this.challengeSuccessRate,
    required this.recoveryScoreAvg,
  });

  factory AnalyticsSummary.empty() {
    return const AnalyticsSummary(
      screenTimeTrend: [],
      topApps: [],
      avgDailyScreenMinutes: 0,
      totalLocks30d: 0,
      challengeSuccessRate: 0,
      recoveryScoreAvg: 0,
    );
  }
}
