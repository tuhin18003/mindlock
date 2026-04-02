class ActivityEvent {
  final String eventType; // 'lock', 'unlock', 'challenge', 'focus', 'emergency'
  final String eventId;
  final String? packageName;
  final String? appName;
  final String? method;
  final int? rewardMinutes;
  final String? result;
  final String occurredAt;

  const ActivityEvent({
    required this.eventType,
    required this.eventId,
    this.packageName,
    this.appName,
    this.method,
    this.rewardMinutes,
    this.result,
    required this.occurredAt,
  });

  factory ActivityEvent.fromJson(Map<String, dynamic> json) {
    return ActivityEvent(
      eventType: json['event_type'] as String,
      eventId: json['event_id'] as String,
      packageName: json['package_name'] as String?,
      appName: json['app_name'] as String?,
      method: json['method'] as String?,
      rewardMinutes: json['reward_minutes'] as int?,
      result: json['result'] as String?,
      occurredAt: json['occurred_at'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'event_type': eventType,
      'event_id': eventId,
      'package_name': packageName,
      'app_name': appName,
      'method': method,
      'reward_minutes': rewardMinutes,
      'result': result,
      'occurred_at': occurredAt,
    };
  }
}

class HistoryStats {
  final int periodDays;
  final int totalLocks;
  final int totalChallenges;
  final int totalEmergencyUnlocks;
  final int totalRecoveredMinutes;
  final int totalFocusMinutes;
  final double challengeSuccessRate;
  final String? mostLockedApp;

  const HistoryStats({
    required this.periodDays,
    required this.totalLocks,
    required this.totalChallenges,
    required this.totalEmergencyUnlocks,
    required this.totalRecoveredMinutes,
    required this.totalFocusMinutes,
    required this.challengeSuccessRate,
    this.mostLockedApp,
  });

  factory HistoryStats.fromJson(Map<String, dynamic> json) {
    return HistoryStats(
      periodDays: json['period_days'] as int? ?? 30,
      totalLocks: json['total_locks'] as int? ?? 0,
      totalChallenges: json['total_challenges'] as int? ?? 0,
      totalEmergencyUnlocks: json['total_emergency_unlocks'] as int? ?? 0,
      totalRecoveredMinutes: json['total_recovered_minutes'] as int? ?? 0,
      totalFocusMinutes: json['total_focus_minutes'] as int? ?? 0,
      challengeSuccessRate: (json['challenge_success_rate'] as num?)?.toDouble() ?? 0.0,
      mostLockedApp: json['most_locked_app'] as String?,
    );
  }

  factory HistoryStats.empty() {
    return const HistoryStats(
      periodDays: 30,
      totalLocks: 0,
      totalChallenges: 0,
      totalEmergencyUnlocks: 0,
      totalRecoveredMinutes: 0,
      totalFocusMinutes: 0,
      challengeSuccessRate: 0.0,
    );
  }
}
