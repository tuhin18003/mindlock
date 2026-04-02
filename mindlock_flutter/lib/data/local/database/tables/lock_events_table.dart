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

