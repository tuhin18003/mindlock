class StorageKeys {
  StorageKeys._();

  // Secure storage keys
  static const String accessToken = 'access_token';
  static const String refreshToken = 'refresh_token';
  static const String userId = 'user_id';
  static const String deviceId = 'device_id';

  // Shared prefs keys
  static const String onboardingComplete = 'onboarding_complete';
  static const String themeMode = 'theme_mode';
  static const String locale = 'locale';
  static const String entitlementCache = 'entitlement_cache';
  static const String entitlementExpiry = 'entitlement_expiry';
  static const String featureFlagsCache = 'feature_flags_cache';
  static const String lastSyncTimestamp = 'last_sync_timestamp';
  static const String pendingSyncQueue = 'pending_sync_queue';
  static const String analyticsQueue = 'analytics_queue';
  static const String notificationPrefs = 'notification_prefs';
  static const String userProfile = 'user_profile';
  static const String appVersion = 'cached_app_version';
}
