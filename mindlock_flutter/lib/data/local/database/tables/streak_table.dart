import 'package:drift/drift.dart';

class StreakTable extends Table {
  @override
  String get tableName => 'streak';

  IntColumn get id => integer().withDefault(const Constant(1))();
  IntColumn get currentStreak => integer().withDefault(const Constant(0))();
  IntColumn get longestStreak => integer().withDefault(const Constant(0))();
  TextColumn get lastStreakDate => text().nullable()(); // YYYY-MM-DD
  TextColumn get streakStartDate => text().nullable()();
  IntColumn get totalStreakDays => integer().withDefault(const Constant(0))();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
