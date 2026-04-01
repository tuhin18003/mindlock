import 'package:flutter/services.dart';

/// AppUsageBridge — platform channel interface for Android app usage stats.
///
/// Isolates all native Android integration behind this abstraction.
/// The platform channel is implemented on the Android side in Kotlin.
class AppUsageBridge {
  static const _channel = MethodChannel('com.mindlock.app/usage_stats');

  /// Get app usage data for a specific date (YYYY-MM-DD).
  static Future<List<AppUsageEntry>> getUsageForDate(String date) async {
    try {
      final result = await _channel.invokeMethod<List>('getUsageForDate', {
        'date': date,
      });

      return result
          ?.map((item) => AppUsageEntry.fromMap(Map<String, dynamic>.from(item)))
          .toList() ?? [];
    } on PlatformException catch (e) {
      // Gracefully degrade — return empty if permission not granted
      if (e.code == 'PERMISSION_DENIED') return [];
      rethrow;
    }
  }

  /// Check if usage stats permission is granted.
  static Future<bool> hasUsageStatsPermission() async {
    try {
      return await _channel.invokeMethod<bool>('hasUsageStatsPermission') ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Open system settings to grant usage stats permission.
  static Future<void> openUsageStatsSettings() async {
    try {
      await _channel.invokeMethod('openUsageStatsSettings');
    } on PlatformException {
      // Ignore — best effort
    }
  }

  /// Get all installed apps (name + package name).
  static Future<List<InstalledApp>> getInstalledApps() async {
    try {
      final result = await _channel.invokeMethod<List>('getInstalledApps');
      return result
          ?.map((item) => InstalledApp.fromMap(Map<String, dynamic>.from(item)))
          .toList() ?? [];
    } on PlatformException {
      return [];
    }
  }

  /// Check if accessibility service is enabled (for foreground detection).
  static Future<bool> hasAccessibilityPermission() async {
    try {
      return await _channel.invokeMethod<bool>('hasAccessibilityPermission') ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Get the currently foreground app package name.
  static Future<String?> getForegroundApp() async {
    try {
      return await _channel.invokeMethod<String?>('getForegroundApp');
    } on PlatformException {
      return null;
    }
  }
}

class AppUsageEntry {
  final String packageName;
  final String appName;
  final int usageSeconds;
  final int openCount;
  final String? category;

  const AppUsageEntry({
    required this.packageName,
    required this.appName,
    required this.usageSeconds,
    required this.openCount,
    this.category,
  });

  factory AppUsageEntry.fromMap(Map<String, dynamic> map) => AppUsageEntry(
    packageName: map['package_name'] as String,
    appName: map['app_name'] as String,
    usageSeconds: map['usage_seconds'] as int,
    openCount: map['open_count'] as int? ?? 0,
    category: map['category'] as String?,
  );
}

class InstalledApp {
  final String packageName;
  final String appName;
  final String? category;

  const InstalledApp({
    required this.packageName,
    required this.appName,
    this.category,
  });

  factory InstalledApp.fromMap(Map<String, dynamic> map) => InstalledApp(
    packageName: map['package_name'] as String,
    appName: map['app_name'] as String,
    category: map['category'] as String?,
  );
}
