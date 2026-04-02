import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/local/database/database_provider.dart';
import '../../../../services/tracking/usage_tracker_service.dart';

part 'lock_screen_provider.freezed.dart';
part 'lock_screen_provider.g.dart';

enum UnlockMethodType {
  challenge,
  reflection,
  learningTask,
  miniChallenge,
  focusTimer,
  habitTask,
  delayTimer,
}

@freezed
class UnlockMethod with _$UnlockMethod {
  const factory UnlockMethod({
    required UnlockMethodType type,
    required String title,
    required String description,
    required int rewardMinutes,
    required bool isPro,
    String? challengeId,
    IconData? icon,
  }) = _UnlockMethod;
}

@freezed
class LockScreenState with _$LockScreenState {
  const factory LockScreenState({
    required String packageName,
    required String appName,
    required int usedSeconds,
    required int limitSeconds,
    required bool strictMode,
    required bool canUseEmergencyUnlock,
    required int recoveredMinutesToday,
    required String motivationalMessage,
    required List<UnlockMethod> availableMethods,
  }) = _LockScreenState;
}

@riverpod
class LockScreenStateNotifier extends _$LockScreenStateNotifier {
  @override
  Future<LockScreenState> build(String packageName) async {
    final tracker = ref.read(usageTrackerServiceProvider);
    final db = ref.read(appDatabaseProvider);
    final usedSeconds = await tracker.getUsageSecondsToday(packageName);

    // Load actual limit from local monitored_apps table
    final monitoredApp = await db.monitoredAppsDao.getByPackage(packageName);
    final limitMinutes = monitoredApp?.dailyLimitMinutes ?? 30;
    final limitSeconds = limitMinutes * 60;
    final strictMode = monitoredApp?.strictMode ?? false;

    return LockScreenState(
      packageName: packageName,
      appName: monitoredApp?.appName ?? _getAppName(packageName),
      usedSeconds: usedSeconds,
      limitSeconds: limitSeconds,
      strictMode: strictMode,
      canUseEmergencyUnlock: !strictMode,
      recoveredMinutesToday: 0,
      motivationalMessage: _getMotivationalMessage(packageName),
      availableMethods: _buildAvailableMethods(),
    );
  }

  Future<void> useEmergencyUnlock() async {
    final tracker = ref.read(usageTrackerServiceProvider);
    final current = state.valueOrNull;
    if (current == null) return;

    await tracker.recordUnlockEvent(
      packageName: packageName,
      method: 'emergency',
      rewardMinutes: 5,
      wasEmergency: true,
    );
  }

  String _getAppName(String pkg) {
    // Simple lookup — in production loaded from local DB
    final names = {
      'com.instagram.android': 'Instagram',
      'com.zhiliaoapp.musically': 'TikTok',
      'com.twitter.android': 'X (Twitter)',
      'com.facebook.katana': 'Facebook',
      'com.reddit.frontpage': 'Reddit',
    };
    return names[pkg] ?? pkg.split('.').last;
  }

  String _getMotivationalMessage(String pkg) {
    final messages = [
      'You opened this app. But your attention is yours to protect.',
      'Every minute you reclaim is yours forever.',
      'Your future self is watching. What would they choose?',
      'Discipline is remembering what you actually want.',
      'The urge will pass. Your goals won\'t.',
    ];
    return messages[pkg.hashCode.abs() % messages.length];
  }

  List<UnlockMethod> _buildAvailableMethods() => [
    const UnlockMethod(
      type: UnlockMethodType.reflection,
      title: 'Quick Reflection',
      description: 'Answer one mindful question',
      rewardMinutes: 5,
      isPro: false,
      challengeId: 'reflection_default',
    ),
    const UnlockMethod(
      type: UnlockMethodType.delayTimer,
      title: 'Wait 5 Minutes',
      description: 'Commit to a short pause',
      rewardMinutes: 5,
      isPro: false,
    ),
    const UnlockMethod(
      type: UnlockMethodType.learningTask,
      title: 'Learn Something',
      description: 'Complete a quick lesson',
      rewardMinutes: 10,
      isPro: false,
      challengeId: 'learn_default',
    ),
    const UnlockMethod(
      type: UnlockMethodType.focusTimer,
      title: 'Focus Session First',
      description: 'Complete 10 minutes of focus',
      rewardMinutes: 15,
      isPro: true,
    ),
    const UnlockMethod(
      type: UnlockMethodType.habitTask,
      title: 'Complete a Habit',
      description: 'Do one healthy habit task',
      rewardMinutes: 10,
      isPro: true,
    ),
  ];
}
