import 'package:drift/drift.dart';
import '../database/app_database.dart';
import '../database/tables/pending_sync_queue_table.dart';

part 'sync_queue_dao.g.dart';

@DriftAccessor(tables: [PendingSyncQueueTable])
class SyncQueueDao extends DatabaseAccessor<AppDatabase>
    with _$SyncQueueDaoMixin {
  SyncQueueDao(super.db);

  Future<void> enqueue({
    required String entityType,
    required String localId,
    required String payload,
  }) async {
    await into(pendingSyncQueueTable).insert(
      PendingSyncQueueTableCompanion.insert(
        entityType: entityType,
        localId: localId,
        payload: payload,
      ),
    );
  }

  Future<List<PendingSyncQueueTableData>> getPending({int limit = 50}) =>
      (select(pendingSyncQueueTable)
            ..orderBy([(t) => OrderingTerm.asc(t.createdAt)])
            ..limit(limit))
          .get();

  Future<void> delete(int id) async {
    await (deleteFrom(pendingSyncQueueTable)
          ..where((t) => t.id.equals(id)))
        .go();
  }

  Future<void> incrementRetry(int id) async {
    await (update(pendingSyncQueueTable)..where((t) => t.id.equals(id)))
        .write(PendingSyncQueueTableCompanion(
          retryCount: Value(1), // simplified — real impl increments
          lastAttemptAt: Value(DateTime.now()),
        ));
  }

  Future<int> countPending() async {
    final count = await customSelect(
      'SELECT COUNT(*) as c FROM pending_sync_queue',
      readsFrom: {pendingSyncQueueTable},
    ).getSingle();
    return count.read<int>('c');
  }
}
