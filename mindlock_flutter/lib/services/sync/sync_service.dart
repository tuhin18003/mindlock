import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:convert';
import '../../data/local/database/app_database.dart';
import '../../core/constants/storage_keys.dart';
import '../storage/prefs_service.dart';
import '../storage/secure_storage_service.dart';
import '../../core/network/api_client.dart';

part 'sync_service.g.dart';

@riverpod
SyncService syncService(Ref ref) {
  return SyncService(
    db: ref.read(appDatabaseProvider),
    prefs: ref.read(prefsServiceProvider).requireValue,
    secureStorage: ref.read(secureStorageServiceProvider),
  );
}

/// SyncService — uploads pending local events to the backend.
///
/// Offline-first: all events are written locally first,
/// then synced to the server when connectivity is available.
class SyncService {
  final AppDatabase _db;
  final PrefsService _prefs;
  final SecureStorageService _secureStorage;

  bool _isSyncing = false;

  SyncService({
    required AppDatabase db,
    required PrefsService prefs,
    required SecureStorageService secureStorage,
  })  : _db = db,
        _prefs = prefs,
        _secureStorage = secureStorage;

  /// Run a full sync cycle.
  Future<SyncResult> syncAll() async {
    if (_isSyncing) return const SyncResult(synced: false, reason: 'Already syncing');

    final hasConnection = await _hasConnectivity();
    if (!hasConnection) return const SyncResult(synced: false, reason: 'No connectivity');

    _isSyncing = true;
    final results = <String, int>{};
    String? error;

    try {
      results['usage_logs'] = await _syncUsageLogs();
      results['lock_events'] = await _syncLockEvents();
      results['unlock_events'] = await _syncUnlockEvents();
      results['challenge_completions'] = await _syncChallengeCompletions();

      _prefs.setString(
        StorageKeys.lastSyncTimestamp,
        DateTime.now().toIso8601String(),
      );
    } catch (e) {
      error = e.toString();
    } finally {
      _isSyncing = false;
    }

    return SyncResult(
      synced: error == null,
      reason: error,
      counts: results,
    );
  }

  Future<int> _syncUsageLogs() async {
    final unsyncedLogs = await _db.usageLogsDao.getUnsynced();
    if (unsyncedLogs.isEmpty) return 0;

    final payload = unsyncedLogs.map((log) => {
      'package_name': log.packageName,
      'date': log.date,
      'usage_seconds': log.usageSeconds,
      'open_count': log.openCount,
      'category': log.category,
    }).toList();

    await _postToApi('/sync/usage-logs', {
      'device_id': await _getDeviceId(),
      'logs': payload,
    });

    await _db.usageLogsDao.markSynced(unsyncedLogs.map((l) => l.id).toList());
    return unsyncedLogs.length;
  }

  Future<int> _syncLockEvents() async {
    final unsyncedEvents = await _db.lockEventsDao.getUnsynced();
    if (unsyncedEvents.isEmpty) return 0;

    final payload = unsyncedEvents.map((e) => {
      'package_name': e.packageName,
      'app_name': e.appName,
      'usage_seconds_at_lock': e.usageSecondsAtLock,
      'limit_seconds': e.limitSeconds,
      'strict_mode': e.strictMode,
      'trigger_reason': e.triggerReason,
      'locked_at': e.lockedAt.toIso8601String(),
      'local_event_id': e.localEventId,
    }).toList();

    await _postToApi('/sync/lock-events', {
      'device_id': await _getDeviceId(),
      'events': payload,
    });

    await _db.lockEventsDao.markSynced(unsyncedEvents.map((e) => e.localEventId).toList());
    return unsyncedEvents.length;
  }

  Future<int> _syncUnlockEvents() async {
    final unsyncedEvents = await _db.lockEventsDao.getUnsyncedUnlocks();
    if (unsyncedEvents.isEmpty) return 0;

    final payload = unsyncedEvents.map((e) => {
      'package_name': e.packageName,
      'method': e.method,
      'reward_minutes': e.rewardMinutes,
      'was_emergency': e.wasEmergency,
      'relocked': e.relocked,
      'relock_minutes': e.relockMinutes,
      'unlocked_at': e.unlockedAt.toIso8601String(),
      'local_event_id': e.localEventId,
      'lock_event_local_id': e.lockEventLocalId,
    }).toList();

    await _postToApi('/sync/unlock-events', {
      'device_id': await _getDeviceId(),
      'events': payload,
    });

    await _db.lockEventsDao.markUnlocksSynced(unsyncedEvents.map((e) => e.localEventId).toList());
    return unsyncedEvents.length;
  }

  Future<int> _syncChallengeCompletions() async {
    // Handled similarly — omitted for brevity, same pattern
    return 0;
  }

  Future<void> _postToApi(String endpoint, Map<String, dynamic> data) async {
    // Direct HTTP call using stored auth token
    // In production this would use the Dio client from the DI container
    // For now this is a placeholder — will be wired in Phase 3 implementation
  }

  Future<String> _getDeviceId() async {
    return await _secureStorage.read(StorageKeys.deviceId) ?? 'unknown';
  }

  Future<bool> _hasConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }
}

class SyncResult {
  final bool synced;
  final String? reason;
  final Map<String, int> counts;

  const SyncResult({
    required this.synced,
    this.reason,
    this.counts = const {},
  });
}
