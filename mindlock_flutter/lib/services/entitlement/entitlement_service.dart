import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/storage_keys.dart';
import '../storage/prefs_service.dart';

part 'entitlement_service.g.dart';

@riverpod
EntitlementService entitlementService(Ref ref) {
  return EntitlementService(ref.read(prefsServiceProvider).requireValue);
}

/// EntitlementService — client-side feature gating.
///
/// NEVER trust local state for payment flows.
/// Backend is always the authority for Pro access.
/// This class caches the server's entitlement response locally
/// for offline access, with a TTL-based refresh.
class EntitlementService {
  final PrefsService _prefs;

  EntitlementService(this._prefs);

  EntitlementSnapshot? _cached;

  /// Load entitlement from cache (used on app start before network call).
  EntitlementSnapshot loadCached() {
    final raw = _prefs.getJson(StorageKeys.entitlementCache);
    if (raw == null) return const EntitlementSnapshot.free();

    final expiry = _prefs.getInt(StorageKeys.entitlementExpiry);
    if (expiry != null && DateTime.now().millisecondsSinceEpoch > expiry) {
      return const EntitlementSnapshot.free(); // expired cache
    }

    _cached = EntitlementSnapshot.fromJson(raw);
    return _cached!;
  }

  /// Update cache from API response.
  void updateFromServer(Map<String, dynamic> entitlementJson) {
    _prefs.setJson(StorageKeys.entitlementCache, entitlementJson);
    _prefs.setInt(
      StorageKeys.entitlementExpiry,
      DateTime.now()
          .add(const Duration(minutes: AppConstants.entitlementCacheTtlMinutes))
          .millisecondsSinceEpoch,
    );
    _cached = EntitlementSnapshot.fromJson(entitlementJson);
  }

  /// Check if user has Pro access.
  bool get isPro => _cached?.isPro ?? false;

  /// Get current snapshot.
  EntitlementSnapshot get snapshot => _cached ?? const EntitlementSnapshot.free();

  /// Clear cache on logout.
  void clear() {
    _prefs.remove(StorageKeys.entitlementCache);
    _prefs.remove(StorageKeys.entitlementExpiry);
    _cached = null;
  }

  /// Feature gate check — single source of truth on mobile.
  bool canAccess(MobileFeature feature) {
    if (feature.requiresPro && !isPro) return false;
    return true;
  }
}

class EntitlementSnapshot {
  final String tier;
  final bool isPro;
  final String? source;
  final String? status;
  final String? expiresAt;
  final bool isLifetime;
  final int? daysRemaining;
  final bool trialAvailable;

  const EntitlementSnapshot({
    required this.tier,
    required this.isPro,
    this.source,
    this.status,
    this.expiresAt,
    required this.isLifetime,
    this.daysRemaining,
    required this.trialAvailable,
  });

  const EntitlementSnapshot.free()
      : tier = 'free',
        isPro = false,
        source = null,
        status = 'none',
        expiresAt = null,
        isLifetime = false,
        daysRemaining = null,
        trialAvailable = true;

  factory EntitlementSnapshot.fromJson(Map<String, dynamic> json) =>
      EntitlementSnapshot(
        tier: json['tier'] ?? 'free',
        isPro: json['is_pro'] ?? false,
        source: json['source'],
        status: json['status'],
        expiresAt: json['expires_at'],
        isLifetime: json['is_lifetime'] ?? false,
        daysRemaining: json['days_remaining'],
        trialAvailable: json['trial_available'] ?? true,
      );

  Map<String, dynamic> toJson() => {
    'tier': tier,
    'is_pro': isPro,
    'source': source,
    'status': status,
    'expires_at': expiresAt,
    'is_lifetime': isLifetime,
    'days_remaining': daysRemaining,
    'trial_available': trialAvailable,
  };
}

/// All Pro-gated features, declared in one place.
enum MobileFeature {
  advancedChallenges(requiresPro: true),
  strictMode(requiresPro: true),
  recoveryMode(requiresPro: true),
  analyticsDetailed(requiresPro: true),
  customLimits(requiresPro: true),
  weeklyReports(requiresPro: true),
  moodTracking(requiresPro: true),
  behaviorInsights(requiresPro: true),
  adaptiveRecommendations(requiresPro: true),
  unlimitedMonitoredApps(requiresPro: true),
  // Free features
  basicTracking(requiresPro: false),
  basicLocking(requiresPro: false),
  basicChallenges(requiresPro: false),
  basicDashboard(requiresPro: false),
  focusTimer(requiresPro: false);

  final bool requiresPro;
  const MobileFeature({required this.requiresPro});
}
