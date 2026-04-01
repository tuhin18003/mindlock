import 'package:drift/drift.dart';

class FocusSessionsTable extends Table {
  @override
  String get tableName => 'focus_sessions';

  TextColumn get localEventId => text()();
  IntColumn get plannedMinutes => integer()();
  IntColumn get actualMinutes => integer().nullable()();
  TextColumn get status => text().withDefault(const Constant('active'))();
  TextColumn get label => text().nullable()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get endedAt => dateTime().nullable()();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {localEventId};
}
