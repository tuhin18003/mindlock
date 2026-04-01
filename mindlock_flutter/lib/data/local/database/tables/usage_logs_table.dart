import 'package:drift/drift.dart';

class UsageLogsTable extends Table {
  @override
  String get tableName => 'usage_logs';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get packageName => text()();
  TextColumn get date => text()(); // YYYY-MM-DD
  IntColumn get usageSeconds => integer().withDefault(const Constant(0))();
  IntColumn get openCount => integer().withDefault(const Constant(0))();
  TextColumn get category => text().nullable()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();
}
