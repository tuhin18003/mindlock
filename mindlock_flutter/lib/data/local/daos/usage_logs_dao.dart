import 'package:drift/drift.dart';
import '../database/app_database.dart';
import '../database/tables/usage_logs_table.dart';

part 'usage_logs_dao.g.dart';

@DriftAccessor(tables: [UsageLogsTable])
class UsageLogsDao extends DatabaseAccessor<AppDatabase>
    with _$UsageLogsDaoMixin {
  UsageLogsDao(super.db);

  Future<UsageLogsTableData?> getLog(String packageName, String date) =>
      (select(usageLogsTable)
            ..where((t) => t.packageName.equals(packageName) & t.date.equals(date)))
          .getSingleOrNull();

  Future<List<UsageLogsTableData>> getLogsForDate(String date) =>
      (select(usageLogsTable)
            ..where((t) => t.date.equals(date))
            ..orderBy([(t) => OrderingTerm.desc(t.usageSeconds)]))
          .get();

  Future<List<UsageLogsTableData>> getUnsynced() =>
      (select(usageLogsTable)..where((t) => t.synced.equals(false))).get();

  Future<void> upsertLog({
    required String packageName,
    required String date,
    required int usageSeconds,
    int openCount = 0,
    String? category,
  }) async {
    await into(usageLogsTable).insertOnConflictUpdate(
      UsageLogsTableCompanion.insert(
        packageName: packageName,
        date: date,
        usageSeconds: Value(usageSeconds),
        openCount: Value(openCount),
        category: Value(category),
        synced: const Value(false),
      ),
    );
  }

  Future<void> markSynced(List<int> ids) async {
    await (update(usageLogsTable)..where((t) => t.id.isIn(ids)))
        .write(const UsageLogsTableCompanion(synced: Value(true)));
  }
}
