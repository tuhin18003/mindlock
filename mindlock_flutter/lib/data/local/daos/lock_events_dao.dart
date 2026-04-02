import 'package:drift/drift.dart';
import '../database/app_database.dart';
import '../database/tables/lock_events_table.dart';
import '../database/tables/unlock_events_table.dart';

part 'lock_events_dao.g.dart';

@DriftAccessor(tables: [LockEventsTable, UnlockEventsTable])
class LockEventsDao extends DatabaseAccessor<AppDatabase>
    with _$LockEventsDaoMixin {
  LockEventsDao(super.db);

  Future<void> insertEvent({
    required String localEventId,
    required String packageName,
    String? appName,
    required int usageSecondsAtLock,
    required int limitSeconds,
    bool strictMode = false,
    String triggerReason = 'limit_reached',
    required DateTime lockedAt,
  }) async {
    await into(lockEventsTable).insert(
      LockEventsTableCompanion.insert(
        localEventId: localEventId,
        packageName: packageName,
        appName: Value(appName),
        usageSecondsAtLock: usageSecondsAtLock,
        limitSeconds: limitSeconds,
        strictMode: Value(strictMode),
        triggerReason: Value(triggerReason),
        lockedAt: lockedAt,
        synced: const Value(false),
      ),
    );
  }

  Future<List<LockEventsTableData>> getUnsynced() =>
      (select(lockEventsTable)..where((t) => t.synced.equals(false))).get();

  Future<void> markSynced(List<String> localIds) async {
    await (update(lockEventsTable)..where((t) => t.localEventId.isIn(localIds)))
        .write(const LockEventsTableCompanion(synced: Value(true)));
  }

  Future<void> insertUnlockEvent({
    required String localEventId,
    String? lockEventLocalId,
    required String packageName,
    required String method,
    int rewardMinutes = 0,
    bool wasEmergency = false,
    bool relocked = false,
    int? relockMinutes,
    required DateTime unlockedAt,
  }) async {
    await into(unlockEventsTable).insert(
      UnlockEventsTableCompanion.insert(
        localEventId: localEventId,
        lockEventLocalId: Value(lockEventLocalId),
        packageName: packageName,
        method: method,
        rewardMinutes: Value(rewardMinutes),
        wasEmergency: Value(wasEmergency),
        relocked: Value(relocked),
        relockMinutes: Value(relockMinutes),
        unlockedAt: unlockedAt,
        synced: const Value(false),
      ),
    );
  }

  Future<List<UnlockEventsTableData>> getUnsyncedUnlocks() =>
      (select(unlockEventsTable)..where((t) => t.synced.equals(false))).get();

  Future<void> markUnlocksSynced(List<String> localIds) async {
    await (update(unlockEventsTable)..where((t) => t.localEventId.isIn(localIds)))
        .write(const UnlockEventsTableCompanion(synced: Value(true)));
  }
}
