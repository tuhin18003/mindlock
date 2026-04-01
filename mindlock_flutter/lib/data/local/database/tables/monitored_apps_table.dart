import 'package:drift/drift.dart';

class MonitoredAppsTable extends Table {
  @override
  String get tableName => 'monitored_apps';

  TextColumn get packageName => text()();
  TextColumn get appName => text()();
  TextColumn get category => text().nullable()();
  BoolColumn get isTracked => boolean().withDefault(const Constant(true))();
  BoolColumn get isLocked => boolean().withDefault(const Constant(false))();
  BoolColumn get strictMode => boolean().withDefault(const Constant(false))();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get pendingSync => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {packageName};
}
