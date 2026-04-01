import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';
import '../../../core/constants/app_constants.dart';
import 'tables/monitored_apps_table.dart';
import 'tables/usage_logs_table.dart';
import 'tables/lock_events_table.dart';
import 'tables/unlock_events_table.dart';
import 'tables/challenge_completions_table.dart';
import 'tables/focus_sessions_table.dart';
import 'tables/emergency_unlocks_table.dart';
import 'tables/pending_sync_queue_table.dart';
import 'tables/analytics_events_table.dart';
import 'tables/streak_table.dart';
import '../daos/monitored_apps_dao.dart';
import '../daos/usage_logs_dao.dart';
import '../daos/lock_events_dao.dart';
import '../daos/sync_queue_dao.dart';
import '../daos/analytics_dao.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    MonitoredAppsTable,
    UsageLogsTable,
    LockEventsTable,
    UnlockEventsTable,
    ChallengeCompletionsTable,
    FocusSessionsTable,
    EmergencyUnlocksTable,
    PendingSyncQueueTable,
    AnalyticsEventsTable,
    StreakTable,
  ],
  daos: [
    MonitoredAppsDao,
    UsageLogsDao,
    LockEventsDao,
    SyncQueueDao,
    AnalyticsDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => AppConstants.dbVersion;

  static QueryExecutor _openConnection() {
    return LazyDatabase(() async {
      final dbFolder = await getApplicationDocumentsDirectory();
      final file = File(p.join(dbFolder.path, AppConstants.dbName));
      return NativeDatabase.createInBackground(file);
    });
  }
}
