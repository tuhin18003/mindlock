import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/local/database/app_database.dart';
import '../../../../data/local/database/database_provider.dart';
import '../../../../services/storage/prefs_service.dart';
import '../../../../services/storage/secure_storage_service.dart';

class SettingsState {
  final bool pushNotificationsEnabled;
  final bool emailNotificationsEnabled;
  final bool streakAlertsEnabled;
  final bool weeklyReportEnabled;
  final bool challengeRemindersEnabled;
  final bool limitWarningsEnabled;
  final String timezone;
  final bool isLoading;

  const SettingsState({
    this.pushNotificationsEnabled = true,
    this.emailNotificationsEnabled = true,
    this.streakAlertsEnabled = true,
    this.weeklyReportEnabled = false,
    this.challengeRemindersEnabled = true,
    this.limitWarningsEnabled = true,
    this.timezone = 'UTC',
    this.isLoading = false,
  });

  SettingsState copyWith({
    bool? pushNotificationsEnabled,
    bool? emailNotificationsEnabled,
    bool? streakAlertsEnabled,
    bool? weeklyReportEnabled,
    bool? challengeRemindersEnabled,
    bool? limitWarningsEnabled,
    String? timezone,
    bool? isLoading,
  }) {
    return SettingsState(
      pushNotificationsEnabled: pushNotificationsEnabled ?? this.pushNotificationsEnabled,
      emailNotificationsEnabled: emailNotificationsEnabled ?? this.emailNotificationsEnabled,
      streakAlertsEnabled: streakAlertsEnabled ?? this.streakAlertsEnabled,
      weeklyReportEnabled: weeklyReportEnabled ?? this.weeklyReportEnabled,
      challengeRemindersEnabled: challengeRemindersEnabled ?? this.challengeRemindersEnabled,
      limitWarningsEnabled: limitWarningsEnabled ?? this.limitWarningsEnabled,
      timezone: timezone ?? this.timezone,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  final AppDatabase _db;
  final PrefsService _prefs;
  final SecureStorageService _secureStorage;

  SettingsNotifier(this._db, this._prefs, this._secureStorage)
      : super(const SettingsState());

  void setPushNotifications(bool value) {
    state = state.copyWith(pushNotificationsEnabled: value);
  }

  void setEmailNotifications(bool value) {
    state = state.copyWith(emailNotificationsEnabled: value);
  }

  void setStreakAlerts(bool value) {
    state = state.copyWith(streakAlertsEnabled: value);
  }

  void setWeeklyReport(bool value) {
    state = state.copyWith(weeklyReportEnabled: value);
  }

  void setChallengeReminders(bool value) {
    state = state.copyWith(challengeRemindersEnabled: value);
  }

  void setLimitWarnings(bool value) {
    state = state.copyWith(limitWarningsEnabled: value);
  }

  void setTimezone(String tz) {
    state = state.copyWith(timezone: tz);
  }

  Future<void> clearLocalData() async {
    state = state.copyWith(isLoading: true);
    try {
      // Clear all local Drift tables
      await _db.delete(_db.usageLogsTable).go();
      await _db.delete(_db.lockEventsTable).go();
      await _db.delete(_db.unlockEventsTable).go();
      await _db.delete(_db.challengeCompletionsTable).go();
      await _db.delete(_db.focusSessionsTable).go();
      await _db.delete(_db.emergencyUnlocksTable).go();
      await _db.delete(_db.pendingSyncQueueTable).go();
      await _db.delete(_db.analyticsEventsTable).go();
      // Clear shared prefs cache (keep auth token + onboarding flag)
      _prefs.remove('entitlement_cache');
      _prefs.remove('entitlement_expiry');
      _prefs.remove('feature_flags_cache');
      _prefs.remove('last_sync_timestamp');
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier(
    ref.watch(appDatabaseProvider),
    ref.watch(prefsServiceProvider).requireValue,
    ref.watch(secureStorageServiceProvider),
  );
});
