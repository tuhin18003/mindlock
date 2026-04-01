import 'package:drift/drift.dart';
import '../database/app_database.dart';
import '../database/tables/analytics_events_table.dart';

part 'analytics_dao.g.dart';

@DriftAccessor(tables: [AnalyticsEventsTable])
class AnalyticsDao extends DatabaseAccessor<AppDatabase>
    with _$AnalyticsDaoMixin {
  AnalyticsDao(super.db);

  Future<void> insertEvent({
    required String eventName,
    String? sessionId,
    required String properties,
    String? entitlementTier,
    required DateTime occurredAt,
  }) async {
    await into(analyticsEventsTable).insert(
      AnalyticsEventsTableCompanion.insert(
        eventName: eventName,
        sessionId: Value(sessionId),
        properties: Value(properties),
        entitlementTier: Value(entitlementTier),
        occurredAt: occurredAt,
        sent: const Value(false),
      ),
    );
  }

  Future<List<AnalyticsEventsTableData>> getUnsent({int limit = 50}) =>
      (select(analyticsEventsTable)
            ..where((t) => t.sent.equals(false))
            ..orderBy([(t) => OrderingTerm.asc(t.occurredAt)])
            ..limit(limit))
          .get();

  Future<void> markSent(List<int> ids) async {
    await (update(analyticsEventsTable)..where((t) => t.id.isIn(ids)))
        .write(const AnalyticsEventsTableCompanion(sent: Value(true)));
  }

  Future<void> deleteOldSent({int keepDays = 7}) async {
    final cutoff = DateTime.now().subtract(Duration(days: keepDays));
    await (deleteFrom(analyticsEventsTable)
          ..where((t) => t.sent.equals(true) & t.occurredAt.isSmallerThanValue(cutoff)))
        .go();
  }
}
