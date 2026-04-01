import 'package:drift/drift.dart';

class ChallengeCompletionsTable extends Table {
  @override
  String get tableName => 'challenge_completions';

  TextColumn get localEventId => text()();
  IntColumn get challengeId => integer()();
  TextColumn get lockEventLocalId => text().nullable()();
  TextColumn get packageName => text().nullable()();
  TextColumn get result => text()(); // completed, skipped, failed
  IntColumn get timeSeconds => integer().nullable()();
  IntColumn get rewardGrantedMinutes => integer().withDefault(const Constant(0))();
  TextColumn get userResponse => text().nullable()();
  DateTimeColumn get completedAt => dateTime()();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {localEventId};
}
