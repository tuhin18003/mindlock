import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import '../../data/local/database/app_database.dart';
import '../entitlement/entitlement_service.dart';

part 'analytics_service.g.dart';

@riverpod
AnalyticsService analyticsService(Ref ref) {
  return AnalyticsService(
    db: ref.read(appDatabaseProvider),
    entitlementService: ref.read(entitlementServiceProvider),
  );
}

/// AnalyticsService — tracks product events locally, then batches to server.
///
/// Events are written to local DB immediately (no blocking).
/// A background job flushes them to the analytics ingest API.
class AnalyticsService {
  final AppDatabase _db;
  final EntitlementService _entitlementService;
  static const _uuid = Uuid();

  String? _sessionId;

  AnalyticsService({
    required AppDatabase db,
    required EntitlementService entitlementService,
  })  : _db = db,
        _entitlementService = entitlementService;

  void startSession() {
    _sessionId = _uuid.v4();
  }

  Future<void> track(
    AnalyticsEvent event, {
    Map<String, dynamic>? properties,
  }) async {
    await _db.analyticsDao.insertEvent(
      eventName: event.name,
      sessionId: _sessionId,
      properties: jsonEncode(properties ?? {}),
      entitlementTier: _entitlementService.snapshot.tier,
      occurredAt: DateTime.now(),
    );
  }
}

/// All tracked product events — defined in one place.
enum AnalyticsEvent {
  appOpened,
  onboardingStarted,
  onboardingCompleted,
  permissionRequested,
  permissionGranted,
  loginCompleted,
  registerCompleted,
  monitoredAppAdded,
  limitSet,
  lockTriggered,
  lockScreenViewed,
  challengeStarted,
  challengeCompleted,
  challengeSkipped,
  emergencyUnlockUsed,
  paywallViewed,
  upgradeStarted,
  upgradeCompleted,
  syncCompleted,
  syncFailed,
  streakExtended,
  streakBroken,
  moodLogged,
  recoveryModeEnabled,
  focusSessionStarted,
  focusSessionCompleted,
  focusSessionAbandoned,
  dashboardViewed,
  historyViewed,
  settingsOpened,
  profileUpdated;

  String get name => switch (this) {
    appOpened => 'app_opened',
    onboardingStarted => 'onboarding_started',
    onboardingCompleted => 'onboarding_completed',
    permissionRequested => 'permission_requested',
    permissionGranted => 'permission_granted',
    loginCompleted => 'login_completed',
    registerCompleted => 'register_completed',
    monitoredAppAdded => 'monitored_app_added',
    limitSet => 'limit_set',
    lockTriggered => 'lock_triggered',
    lockScreenViewed => 'lock_screen_viewed',
    challengeStarted => 'challenge_started',
    challengeCompleted => 'challenge_completed',
    challengeSkipped => 'challenge_skipped',
    emergencyUnlockUsed => 'emergency_unlock_used',
    paywallViewed => 'paywall_viewed',
    upgradeStarted => 'upgrade_started',
    upgradeCompleted => 'upgrade_completed',
    syncCompleted => 'sync_completed',
    syncFailed => 'sync_failed',
    streakExtended => 'streak_extended',
    streakBroken => 'streak_broken',
    moodLogged => 'mood_logged',
    recoveryModeEnabled => 'recovery_mode_enabled',
    focusSessionStarted => 'focus_session_started',
    focusSessionCompleted => 'focus_session_completed',
    focusSessionAbandoned => 'focus_session_abandoned',
    dashboardViewed => 'dashboard_viewed',
    historyViewed => 'history_viewed',
    settingsOpened => 'settings_opened',
    profileUpdated => 'profile_updated',
  };
}
