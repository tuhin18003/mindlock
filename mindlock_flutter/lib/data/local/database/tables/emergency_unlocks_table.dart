import 'package:drift/drift.dart';

class EmergencyUnlocksTable extends Table {
  @override
  String get tableName => 'emergency_unlocks';

  TextColumn get localEventId => text()();
  TextColumn get lockEventLocalId => text().nullable()();
  TextColumn get packageName => text()();
  TextColumn get reason => text().nullable()();
  DateTimeColumn get usedAt => dateTime()();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {localEventId};
}
