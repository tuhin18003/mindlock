import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/local/database/app_database.dart';
import '../../../../data/local/database/database_provider.dart';
import '../../data/models/monitored_app_model.dart';
import '../../data/models/app_device_config_model.dart';
import '../../data/remote/apps_remote_datasource.dart';

class AppsState {
  final List<MonitoredAppModel> apps;
  final Map<String, int> todayUsageSeconds;
  final bool isLoading;
  final String? error;
  final bool isPro;

  const AppsState({
    this.apps = const [],
    this.todayUsageSeconds = const {},
    this.isLoading = false,
    this.error,
    this.isPro = false,
  });

  AppsState copyWith({
    List<MonitoredAppModel>? apps,
    Map<String, int>? todayUsageSeconds,
    bool? isLoading,
    String? error,
    bool? isPro,
    bool clearError = false,
  }) {
    return AppsState(
      apps: apps ?? this.apps,
      todayUsageSeconds: todayUsageSeconds ?? this.todayUsageSeconds,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      isPro: isPro ?? this.isPro,
    );
  }
}

class AppsNotifier extends StateNotifier<AppsState> {
  final AppsRemoteDatasource? _datasource;
  final AppDatabase _db;

  AppsNotifier({AppsRemoteDatasource? datasource, required AppDatabase db})
      : _datasource = datasource,
        _db = db,
        super(const AppsState());

  Future<void> loadApps() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      if (_datasource != null) {
        final config = await _datasource!.getDeviceConfig();
        await _persistAppsToLocal(config.monitoredApps);
        state = state.copyWith(
          apps: config.monitoredApps,
          todayUsageSeconds: config.todayUsageSeconds,
          isPro: config.isPro,
          isLoading: false,
        );
      } else {
        // Offline fallback: read from local DB
        final localApps = await _db.monitoredAppsDao.getAllMonitored();
        final apps = localApps.map(_fromRow).toList();
        state = state.copyWith(
          apps: apps.isNotEmpty ? apps : _mockApps(),
          todayUsageSeconds: _mockUsage(),
          isPro: false,
          isLoading: false,
        );
      }
    } catch (e) {
      // On network error, fall back to local DB
      try {
        final localApps = await _db.monitoredAppsDao.getAllMonitored();
        final apps = localApps.map(_fromRow).toList();
        state = state.copyWith(
          apps: apps.isNotEmpty ? apps : _mockApps(),
          todayUsageSeconds: _mockUsage(),
          isPro: false,
          isLoading: false,
          error: e.toString(),
        );
      } catch (_) {
        state = state.copyWith(isLoading: false, error: e.toString());
      }
    }
  }

  Future<void> setLimit(
    String packageName,
    int dailyLimitMinutes, {
    int? weekdayLimitMinutes,
    int? weekendLimitMinutes,
  }) async {
    try {
      await _datasource?.setLimit(
        packageName,
        dailyLimitMinutes: dailyLimitMinutes,
        weekdayLimitMinutes: weekdayLimitMinutes,
        weekendLimitMinutes: weekendLimitMinutes,
      );
      // Persist locally so lock screen can read limits offline
      await _db.monitoredAppsDao.upsert(MonitoredAppsTableCompanion(
        packageName: Value(packageName),
        appName: Value(_appNameFor(packageName)),
        dailyLimitMinutes: Value(dailyLimitMinutes),
        weekdayLimitMinutes: Value(weekdayLimitMinutes),
        weekendLimitMinutes: Value(weekendLimitMinutes),
        pendingSync: const Value(true),
      ));
      final updated = state.apps.map((app) {
        if (app.packageName == packageName) {
          return app.copyWith(
            dailyLimitMinutes: dailyLimitMinutes,
            weekdayLimitMinutes: weekdayLimitMinutes,
            weekendLimitMinutes: weekendLimitMinutes,
          );
        }
        return app;
      }).toList();
      state = state.copyWith(apps: updated);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> removeLimit(String packageName) async {
    try {
      await _datasource?.removeLimit(packageName);
      await _db.monitoredAppsDao.upsert(MonitoredAppsTableCompanion(
        packageName: Value(packageName),
        appName: Value(_appNameFor(packageName)),
        dailyLimitMinutes: const Value(null),
        weekdayLimitMinutes: const Value(null),
        weekendLimitMinutes: const Value(null),
        pendingSync: const Value(true),
      ));
      final updated = state.apps.map((app) {
        if (app.packageName == packageName) {
          return app.copyWith(clearDailyLimit: true);
        }
        return app;
      }).toList();
      state = state.copyWith(apps: updated);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> toggleLock(String packageName) async {
    final app = state.apps.firstWhere(
      (a) => a.packageName == packageName,
      orElse: () => throw Exception('App not found'),
    );
    final newLocked = !app.isLocked;
    try {
      await _datasource?.toggleLock(
        packageName,
        isLocked: newLocked,
        lockMode: app.lockMode,
      );
      await _db.monitoredAppsDao.setLocked(packageName, newLocked);
      final updated = state.apps.map((a) {
        if (a.packageName == packageName) {
          return a.copyWith(isLocked: newLocked);
        }
        return a;
      }).toList();
      state = state.copyWith(apps: updated);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> setLockMode(String packageName, String lockMode) async {
    final app = state.apps.firstWhere(
      (a) => a.packageName == packageName,
      orElse: () => throw Exception('App not found'),
    );
    try {
      await _datasource?.toggleLock(
        packageName,
        isLocked: app.isLocked,
        lockMode: lockMode,
      );
      final updated = state.apps.map((a) {
        if (a.packageName == packageName) {
          return a.copyWith(lockMode: lockMode);
        }
        return a;
      }).toList();
      state = state.copyWith(apps: updated);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  Future<void> _persistAppsToLocal(List<MonitoredAppModel> apps) async {
    for (final app in apps) {
      await _db.monitoredAppsDao.upsert(MonitoredAppsTableCompanion(
        packageName: Value(app.packageName),
        appName: Value(app.appName),
        dailyLimitMinutes: Value(app.dailyLimitMinutes),
        weekdayLimitMinutes: Value(app.weekdayLimitMinutes),
        weekendLimitMinutes: Value(app.weekendLimitMinutes),
        isLocked: Value(app.isLocked),
        strictMode: Value(app.lockMode == 'strict'),
        pendingSync: const Value(false),
      ));
    }
  }

  MonitoredAppModel _fromRow(MonitoredAppsTableData row) {
    return MonitoredAppModel(
      packageName: row.packageName,
      appName: row.appName,
      dailyLimitMinutes: row.dailyLimitMinutes,
      weekdayLimitMinutes: row.weekdayLimitMinutes,
      weekendLimitMinutes: row.weekendLimitMinutes,
      isLocked: row.isLocked,
      lockMode: row.strictMode ? 'strict' : 'soft',
    );
  }

  String _appNameFor(String packageName) {
    return state.apps
        .firstWhere((a) => a.packageName == packageName,
            orElse: () => MonitoredAppModel(
                  packageName: packageName,
                  appName: packageName.split('.').last,
                  isLocked: false,
                  lockMode: 'soft',
                ))
        .appName;
  }

  // --- Mock data for development/offline ---
  List<MonitoredAppModel> _mockApps() {
    return [
      const MonitoredAppModel(
        packageName: 'com.instagram.android',
        appName: 'Instagram',
        dailyLimitMinutes: 30,
        isLocked: false,
        lockMode: 'soft',
      ),
      const MonitoredAppModel(
        packageName: 'com.twitter.android',
        appName: 'Twitter / X',
        dailyLimitMinutes: 60,
        isLocked: true,
        lockMode: 'soft',
      ),
      const MonitoredAppModel(
        packageName: 'com.zhiliaoapp.musically',
        appName: 'TikTok',
        dailyLimitMinutes: 20,
        isLocked: false,
        lockMode: 'strict',
      ),
      const MonitoredAppModel(
        packageName: 'com.reddit.frontpage',
        appName: 'Reddit',
        isLocked: false,
        lockMode: 'soft',
      ),
    ];
  }

  Map<String, int> _mockUsage() {
    return {
      'com.instagram.android': 1920,
      'com.twitter.android': 3600,
      'com.zhiliaoapp.musically': 900,
      'com.reddit.frontpage': 720,
    };
  }
}

final appsProvider = StateNotifierProvider<AppsNotifier, AppsState>((ref) {
  return AppsNotifier(db: ref.watch(appDatabaseProvider));
});
