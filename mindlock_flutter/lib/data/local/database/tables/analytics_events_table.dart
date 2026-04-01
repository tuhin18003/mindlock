import 'package:drift/drift.dart';

class AnalyticsEventsTable extends Table {
  @override
  String get tableName => 'analytics_events_queue';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get eventName => text()();
  TextColumn get sessionId => text().nullable()();
  TextColumn get properties => text().withDefault(const Constant('{}'))(); // JSON
  TextColumn get entitlementTier => text().nullable()();
  DateTimeColumn get occurredAt => dateTime()();
  BoolColumn get sent => boolean().withDefault(const Constant(false))();
}
