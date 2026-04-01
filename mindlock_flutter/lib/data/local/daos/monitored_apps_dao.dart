import 'package:drift/drift.dart';
import '../database/app_database.dart';
import '../database/tables/monitored_apps_table.dart';

part 'monitored_apps_dao.g.dart';

@DriftAccessor(tables: [MonitoredAppsTable])
class MonitoredAppsDao extends DatabaseAccessor<AppDatabase>
    with _$MonitoredAppsDaoMixin {
  MonitoredAppsDao(super.db);

  Future<List<MonitoredAppsTableData>> getAllMonitored() =>
      select(monitoredAppsTable).get();

  Future<List<MonitoredAppsTableData>> getLocked() => (select(monitoredAppsTable)
        ..where((t) => t.isLocked.equals(true)))
      .get();

  Future<MonitoredAppsTableData?> getByPackage(String packageName) =>
      (select(monitoredAppsTable)
            ..where((t) => t.packageName.equals(packageName)))
          .getSingleOrNull();

  Future<void> upsert(MonitoredAppsTableCompanion companion) =>
      into(monitoredAppsTable).insertOnConflictUpdate(companion);

  Future<void> setLocked(String packageName, bool locked) =>
      (update(monitoredAppsTable)
            ..where((t) => t.packageName.equals(packageName)))
          .write(MonitoredAppsTableCompanion(isLocked: Value(locked)));

  Future<void> markPendingSync(String packageName) =>
      (update(monitoredAppsTable)
            ..where((t) => t.packageName.equals(packageName)))
          .write(const MonitoredAppsTableCompanion(pendingSync: Value(true)));

  Future<List<MonitoredAppsTableData>> getPendingSync() =>
      (select(monitoredAppsTable)..where((t) => t.pendingSync.equals(true)))
          .get();
}
