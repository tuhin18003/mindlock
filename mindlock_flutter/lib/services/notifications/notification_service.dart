import 'package:flutter/material.dart' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// timezone is a transitive dependency of flutter_local_notifications
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;

class NotificationService {
  static const _channelId = 'mindlock_main';
  static const _channelName = 'MindLock Alerts';
  static const _channelDescription =
      'Streak reminders, limit warnings, and weekly reports';

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  NotificationService(this._plugin);

  /// Call once on app start — configures Android channel and requests permission.
  Future<void> initialize() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: darwinInit,
    );

    await _plugin.initialize(initSettings);

    // Create Android notification channel
    const androidChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.high,
      playSound: true,
    );

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(androidChannel);
    await androidPlugin?.requestNotificationsPermission();

    _initialized = true;
  }

  /// Show a warning when the user is approaching their screen time limit.
  Future<void> showLimitWarning({
    required String appName,
    required int usedMinutes,
    required int limitMinutes,
  }) async {
    await _ensureInitialized();
    final remaining = limitMinutes - usedMinutes;
    await _plugin.show(
      _NotificationIds.limitWarning,
      '$appName — ${remaining}m remaining',
      'You\'ve used ${usedMinutes}m of your ${limitMinutes}m limit today.',
      _buildDetails(color: 0xFFFF9800),
    );
  }

  /// Show a streak reminder notification.
  Future<void> showStreakReminder(int currentStreak) async {
    await _ensureInitialized();
    await _plugin.show(
      _NotificationIds.streakReminder,
      currentStreak > 0
          ? 'Keep your $currentStreak-day streak alive! 🔥'
          : 'Start your streak today!',
      'Complete a challenge or focus session before midnight.',
      _buildDetails(color: 0xFFFFD700),
    );
  }

  /// Schedule the weekly report notification every Sunday at 9 AM.
  Future<void> scheduleWeeklyReport() async {
    await _ensureInitialized();

    // Cancel any existing scheduled notification first
    await _plugin.cancel(_NotificationIds.weeklyReport);

    final now = tz.TZDateTime.now(tz.local);
    // Find next Sunday
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      9, // 9 AM
    );

    // Advance to Sunday (weekday 7 in Dart)
    while (scheduledDate.weekday != DateTime.sunday) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 7));
    }

    await _plugin.zonedSchedule(
      _NotificationIds.weeklyReport,
      'Your Weekly MindLock Report is Ready',
      'See how your screen time and focus improved this week.',
      scheduledDate,
      _buildDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  /// Cancel all scheduled and shown notifications.
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  Future<void> _ensureInitialized() async {
    if (!_initialized) await initialize();
  }

  NotificationDetails _buildDetails({int? color}) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        color: color != null ? Color(color) : null,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }
}

// Stable notification IDs
class _NotificationIds {
  static const int limitWarning = 1001;
  static const int streakReminder = 1002;
  static const int weeklyReport = 1003;
  static const int challengeReminder = 1004;
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(FlutterLocalNotificationsPlugin());
});
