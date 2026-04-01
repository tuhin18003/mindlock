import 'package:drift/drift.dart';

class LockEventsTable extends Table {
  @override
  String get tableName => 'lock_events';

  TextColumn get localEventId => text()();
  TextColumn get packageName => text()();
  TextColumn get appName => text().nullable()();
  IntColumn get usageSecondsAtLock => integer()();
  IntColumn get limitSeconds => integer()();
  BoolColumn get strictMode => boolean().withDefault(const Constant(false))();
  TextColumn get triggerReason => text().withDefault(const Constant('limit_reached'))();
  DateTimeColumn get lockedAt => dateTime()();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {localEventId};
}

class UnlockEventsTable extends Table {
  @override
  String get tableName => 'unlock_events';

  TextColumn get localEventId => text()();
  TextColumn get lockEventLocalId => text().nullable()();
  TextColumn get packageName => text()();
  TextColumn get method => text()();
  IntColumn get rewardMinutes => integer().withDefault(const Constant(0))();
  BoolColumn get wasEmergency => boolean().withDefault(const Constant(false))();
  BoolColumn get relocked => boolean().withDefault(const Constant(false))();
  IntColumn get relockMinutes => integer().nullable()();
  DateTimeColumn get unlockedAt => dateTime()();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {localEventId};
}
