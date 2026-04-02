class MonitoredAppModel {
  final String packageName;
  final String appName;
  final int? dailyLimitMinutes;
  final bool isLocked;
  final String lockMode; // 'soft' or 'strict'
  final int? weekdayLimitMinutes;
  final int? weekendLimitMinutes;

  const MonitoredAppModel({
    required this.packageName,
    required this.appName,
    this.dailyLimitMinutes,
    required this.isLocked,
    required this.lockMode,
    this.weekdayLimitMinutes,
    this.weekendLimitMinutes,
  });

  factory MonitoredAppModel.fromJson(Map<String, dynamic> json) {
    return MonitoredAppModel(
      packageName: json['package_name'] as String,
      appName: json['app_name'] as String,
      dailyLimitMinutes: json['daily_limit_minutes'] as int?,
      isLocked: json['is_locked'] as bool? ?? false,
      lockMode: json['lock_mode'] as String? ?? 'soft',
      weekdayLimitMinutes: json['weekday_limit_minutes'] as int?,
      weekendLimitMinutes: json['weekend_limit_minutes'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'package_name': packageName,
      'app_name': appName,
      'daily_limit_minutes': dailyLimitMinutes,
      'is_locked': isLocked,
      'lock_mode': lockMode,
      'weekday_limit_minutes': weekdayLimitMinutes,
      'weekend_limit_minutes': weekendLimitMinutes,
    };
  }

  MonitoredAppModel copyWith({
    String? packageName,
    String? appName,
    int? dailyLimitMinutes,
    bool? isLocked,
    String? lockMode,
    int? weekdayLimitMinutes,
    int? weekendLimitMinutes,
    bool clearDailyLimit = false,
  }) {
    return MonitoredAppModel(
      packageName: packageName ?? this.packageName,
      appName: appName ?? this.appName,
      dailyLimitMinutes: clearDailyLimit ? null : (dailyLimitMinutes ?? this.dailyLimitMinutes),
      isLocked: isLocked ?? this.isLocked,
      lockMode: lockMode ?? this.lockMode,
      weekdayLimitMinutes: weekdayLimitMinutes ?? this.weekdayLimitMinutes,
      weekendLimitMinutes: weekendLimitMinutes ?? this.weekendLimitMinutes,
    );
  }
}
