import 'package:drift/drift.dart';

class PendingSyncQueueTable extends Table {
  @override
  String get tableName => 'pending_sync_queue';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get entityType => text()(); // usage_logs, lock_events, etc.
  TextColumn get localId => text()();
  TextColumn get payload => text()(); // JSON
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get lastAttemptAt => dateTime().nullable()();
}
