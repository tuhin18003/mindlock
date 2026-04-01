class AppConstants {
  AppConstants._();

  // App
  static const String appName = 'MindLock';
  static const String appVersion = '1.0.0';

  // API
  static const String apiBaseUrlProd = 'https://api.mindlock.app/api/v1';
  static const String apiBaseUrlDev = 'http://10.0.2.2:8000/api/v1';
  static const int connectTimeout = 30000;
  static const int receiveTimeout = 30000;

  // Auth tokens
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userIdKey = 'user_id';
  static const String deviceIdKey = 'device_id';

  // Local DB
  static const String dbName = 'mindlock.db';
  static const int dbVersion = 1;

  // Entitlement
  static const String entitlementCacheKey = 'entitlement_cache';
  static const String entitlementTtlKey = 'entitlement_ttl';
  static const int entitlementCacheTtlMinutes = 60;

  // Usage
  static const int defaultUsageSyncIntervalMinutes = 15;
  static const int dailyResetHour = 0; // midnight

  // Lock
  static const int emergencyUnlockCooldownMinutes = 60;
  static const int defaultDelayTimerMinutes = 5;

  // Pagination
  static const int defaultPageSize = 20;

  // Analytics
  static const int analyticsFlushIntervalSeconds = 30;
  static const int analyticsMaxBatchSize = 50;

  // Onboarding
  static const String onboardingCompleteKey = 'onboarding_complete';

  // Feature flags
  static const String featureFlagsCacheKey = 'feature_flags_cache';
}
