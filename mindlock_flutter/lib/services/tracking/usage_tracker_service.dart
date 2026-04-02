import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import '../../data/local/database/app_database.dart';
import '../../data/local/database/database_provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/date_utils.dart';
import '../platform/app_usage_bridge.dart';

part 'usage_tracker_service.g.dart';

@riverpod
UsageTrackerService usageTrackerService(Ref ref) {
  return UsageTrackerService(ref.read(appDatabaseProvider));
}

/// UsageTrackerService — manages daily usage tracking state.
///
/// This is the local engine — operates fully offline.
/// Reads usage from the Android platform bridge and persists locally.
class UsageTrackerService {
  final AppDatabase _db;
  static const _uuid = Uuid();

  UsageTrackerService(this._db);

  /// Fetch fresh usage from platform and persist to local DB.
  Future<void> refreshUsage(String date) async {
    final usageData = await AppUsageBridge.getUsageForDate(date);

    for (final entry in usageData) {
      await _db.usageLogsDao.upsertLog(
        packageName: entry.packageName,
        date: date,
        usageSeconds: entry.usageSeconds,
        openCount: entry.openCount,
        category: entry.category,
      );
    }
  }

  /// Get current usage for a package today.
  Future<int> getUsageSecondsToday(String packageName) async {
    final today = MindLockDateUtils.startOfDay(DateTime.now());
    final log = await _db.usageLogsDao.getLog(packageName, _dateString(today));
    return log?.usageSeconds ?? 0;
  }

  /// Check if a package has exceeded its limit.
  Future<LockCheckResult> checkLockState(
    String packageName,
    int limitSeconds,
    bool strictMode,
  ) async {
    final usedSeconds = await getUsageSecondsToday(packageName);
    final remaining = limitSeconds - usedSeconds;
    final exceeded = usedSeconds >= limitSeconds;

    return LockCheckResult(
      packageName: packageName,
      usedSeconds: usedSeconds,
      limitSeconds: limitSeconds,
      remainingSeconds: remaining.clamp(0, limitSeconds),
      isExceeded: exceeded,
      strictMode: strictMode,
    );
  }

  /// Record a lock event locally.
  Future<String> recordLockEvent({
    required String packageName,
    String? appName,
    required int usageSecondsAtLock,
    required int limitSeconds,
    bool strictMode = false,
    String triggerReason = 'limit_reached',
  }) async {
    final localId = _uuid.v4();
    await _db.lockEventsDao.insertEvent(
      localEventId: localId,
      packageName: packageName,
      appName: appName,
      usageSecondsAtLock: usageSecondsAtLock,
      limitSeconds: limitSeconds,
      strictMode: strictMode,
      triggerReason: triggerReason,
      lockedAt: DateTime.now(),
    );
    return localId;
  }

  /// Record an unlock event locally.
  Future<String> recordUnlockEvent({
    required String packageName,
    required String method,
    String? lockEventLocalId,
    int rewardMinutes = 0,
    bool wasEmergency = false,
  }) async {
    final localId = _uuid.v4();
    await _db.lockEventsDao.insertUnlockEvent(
      localEventId: localId,
      lockEventLocalId: lockEventLocalId,
      packageName: packageName,
      method: method,
      rewardMinutes: rewardMinutes,
      wasEmergency: wasEmergency,
      unlockedAt: DateTime.now(),
    );
    return localId;
  }

  /// Get daily usage summary.
  Future<DailyUsageSummary> getDailySummary(String date) async {
    final logs = await _db.usageLogsDao.getLogsForDate(date);
    final totalSeconds = logs.fold(0, (sum, log) => sum + log.usageSeconds);
    final topApp = logs.isEmpty ? null
        : logs.reduce((a, b) => a.usageSeconds > b.usageSeconds ? a : b);

    return DailyUsageSummary(
      date: date,
      totalScreenSeconds: totalSeconds,
      topDistraction: topApp?.packageName,
      appBreakdown: logs,
    );
  }

  /// Check if we're in a new day — reset daily state if so.
  Future<bool> checkAndHandleDayReset() async {
    final today = _dateString(DateTime.now());
    // This is handled by the OS usage stats API which resets at midnight
    // Our local records use date keys, so old dates are automatically separate
    return true;
  }

  String _dateString(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}

class LockCheckResult {
  final String packageName;
  final int usedSeconds;
  final int limitSeconds;
  final int remainingSeconds;
  final bool isExceeded;
  final bool strictMode;

  const LockCheckResult({
    required this.packageName,
    required this.usedSeconds,
    required this.limitSeconds,
    required this.remainingSeconds,
    required this.isExceeded,
    required this.strictMode,
  });

  double get usedPercent => limitSeconds > 0 ? usedSeconds / limitSeconds : 0;
  int get usedMinutes => usedSeconds ~/ 60;
  int get limitMinutes => limitSeconds ~/ 60;
  int get remainingMinutes => remainingSeconds ~/ 60;
}

class DailyUsageSummary {
  final String date;
  final int totalScreenSeconds;
  final String? topDistraction;
  final List<dynamic> appBreakdown;

  const DailyUsageSummary({
    required this.date,
    required this.totalScreenSeconds,
    this.topDistraction,
    required this.appBreakdown,
  });

  int get totalMinutes => totalScreenSeconds ~/ 60;
}
