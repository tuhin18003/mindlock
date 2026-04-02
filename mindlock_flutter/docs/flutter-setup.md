# MindLock Flutter — Setup & Build Guide

## Requirements

| Tool | Version |
|---|---|
| Flutter SDK | 3.19.0+ |
| Dart SDK | 3.3.0+ |
| Android Studio | Hedgehog (2023.1) or newer |
| JDK | 17+ |
| Android SDK | API 26+ (minSdk), API 34+ (targetSdk) |
| Kotlin | 1.9.23+ |

---

## 1. Install Dependencies

```bash
cd mindlock_flutter
flutter pub get
```

---

## 2. Generate Code (REQUIRED before building)

The project uses `build_runner` for Drift (local DB), Riverpod, and Freezed code generation.

```bash
dart run build_runner build --delete-conflicting-outputs
```

This generates:
- `*.g.dart` — Riverpod providers, Drift DAOs, JSON serialization
- `*.freezed.dart` — Immutable Freezed models

Run this again whenever you modify files that use `@riverpod`, `@freezed`, `@DriftDatabase`, or `@DriftAccessor`.

For continuous generation during development:
```bash
dart run build_runner watch --delete-conflicting-outputs
```

---

## 3. Android Setup

### 3.1 Usage Stats Permission
MindLock requires the `PACKAGE_USAGE_STATS` permission which cannot be requested via the normal runtime permission flow — the user must grant it manually.

The app handles this by checking on startup and redirecting to system settings.

### 3.2 Firebase Setup
1. Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
2. Add an Android app with package name `com.mindlock.app`
3. Download `google-services.json` and place it at: `android/app/google-services.json`
4. Enable Firebase Cloud Messaging (FCM)

### 3.3 Local Development
The API base URL defaults to `http://10.0.2.2:8000/api/v1` (Android emulator loopback for `localhost`).

For physical devices: update `AppConstants.apiBaseUrlDev` in `lib/core/constants/app_constants.dart` to your machine's local IP.

---

## 4. Run the App

```bash
# Debug (emulator or physical device)
flutter run

# Release build
flutter build apk --release

# App Bundle (for Play Store)
flutter build appbundle --release
```

---

## 5. Project Structure

```
lib/
├── main.dart                      # App entry point
├── routes/                        # GoRouter configuration + guards
├── core/
│   ├── constants/                 # AppConstants, StorageKeys
│   ├── errors/                    # Typed failures + exceptions
│   ├── network/                   # Dio + interceptors
│   ├── theme/                     # AppColors, AppTypography, AppSpacing, AppTheme
│   └── utils/                     # DateUtils, Either, UseCase
├── data/
│   └── local/
│       ├── database/              # Drift AppDatabase + tables
│       └── daos/                  # Data access objects
├── features/                      # Feature-first architecture
│   ├── auth/                      # Login, Register, Forgot/Reset password
│   ├── dashboard/                 # Home screen with recovery ring + stats
│   ├── apps/                      # Monitored apps management
│   ├── locks/                     # Lock screen + unlock method flow
│   ├── challenges/                # Challenge library + active challenge
│   ├── history/                   # Activity timeline + stats
│   ├── analytics/                 # Usage analytics charts
│   ├── settings/                  # Notifications, account settings
│   ├── account/                   # User profile + avatar
│   ├── subscription/              # Paywall + plan selector
│   └── onboarding/                # 3-step onboarding flow
├── services/
│   ├── analytics/                 # Event tracking (local queue → backend batch)
│   ├── entitlement/               # Pro access gating (server-authoritative)
│   ├── notifications/             # Local + push notifications
│   ├── platform/                  # AppUsageBridge (platform channel to Kotlin)
│   ├── storage/                   # SecureStorage + PrefsService
│   ├── sync/                      # Offline-first sync to backend
│   └── tracking/                  # Usage tracking engine
└── shared/
    └── widgets/                   # MLButton, MLTextField, ProGate, MLShimmer, MLAppBar
```

---

## 6. Key Architecture Decisions

### Offline-First
All user actions (app locks, unlocks, challenge completions, usage logs) are written to the local Drift SQLite database first with a UUID `localEventId`. `SyncService.syncAll()` uploads them when online.

### Entitlement Authority
The backend is always the source of truth for Pro access. `EntitlementService` caches the server response locally with a 60-minute TTL. Never check billing receipts client-side.

### Feature Gating
Use `ProGate(feature: MobileFeature.myFeature, child: ...)` to wrap any Pro-only widget. Never hardcode `isPro` checks directly in screens.

### State Management
- **Riverpod** with code generation (`@riverpod`) for most providers
- **Freezed** for all immutable state models
- **StateNotifier** for complex mutable state (settings, profile, apps)

---

## 7. Running Backend Locally

See `mindlock_backend/docs/admin-dashboard.md` for backend setup.

Quick start:
```bash
cd mindlock_backend
composer install
cp .env.example .env
php artisan key:generate
php artisan migrate --seed
php artisan serve        # runs on :8000
```

The Flutter app connects to `http://10.0.2.2:8000/api/v1` by default when running on an Android emulator.

---

## 8. Android Permissions Explained

| Permission | Why |
|---|---|
| `PACKAGE_USAGE_STATS` | Read daily app usage stats — core feature |
| `POST_NOTIFICATIONS` | Android 13+ runtime notification permission |
| `SCHEDULE_EXACT_ALARM` | Scheduled streak and limit reminders |
| `RECEIVE_BOOT_COMPLETED` | Restart background sync after device reboot |
| `FOREGROUND_SERVICE` | Background usage monitoring service |
| `READ_MEDIA_IMAGES` | Avatar upload (Android 13+) |
| `INTERNET` | API calls |

---

## 9. Release Signing

Create `android/key.properties`:
```
storePassword=<keystore_password>
keyPassword=<key_password>
keyAlias=mindlock
storeFile=<path_to_keystore>/mindlock.jks
```

Generate keystore:
```bash
keytool -genkey -v -keystore mindlock.jks -keyalg RSA -keysize 2048 \
  -validity 10000 -alias mindlock
```

Then reference in `android/app/build.gradle`.
