# MindLock — Production Deployment Guide

Everything needed to connect the Flutter app to the backend API, build a signed release APK/AAB, and publish to Google Play.

---

## Table of Contents

1. [Backend API Setup](#1-backend-api-setup)
2. [Connect Flutter to the Production API](#2-connect-flutter-to-the-production-api)
3. [Firebase Setup (Push Notifications)](#3-firebase-setup-push-notifications)
4. [Generate the Release Keystore](#4-generate-the-release-keystore)
5. [Configure Signing in Gradle](#5-configure-signing-in-gradle)
6. [Build the Release AAB](#6-build-the-release-aab)
7. [Google Play Console — First Upload](#7-google-play-console--first-upload)
8. [Google Play Console — Subsequent Releases](#8-google-play-console--subsequent-releases)
9. [Environment Variables Reference](#9-environment-variables-reference)
10. [Pre-Launch Checklist](#10-pre-launch-checklist)

---

## 1. Backend API Setup

Before building the app for production, the Laravel backend must be live and reachable.

### Deploy the backend

```bash
# On your server (Ubuntu 22.04 recommended)
cd /var/www/mindlock_backend

composer install --no-dev --optimize-autoloader
cp .env.example .env
php artisan key:generate

# Edit .env with production values (see section 9)
nano .env

php artisan migrate --force
php artisan db:seed --class=RolesAndPermissionsSeeder
php artisan config:cache
php artisan route:cache
php artisan view:cache
php artisan storage:link
```

### Required .env values for production

```dotenv
APP_ENV=production
APP_DEBUG=false
APP_URL=https://api.mindlock.app

DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_DATABASE=mindlock_prod
DB_USERNAME=mindlock
DB_PASSWORD=<strong-password>

SANCTUM_STATEFUL_DOMAINS=api.mindlock.app

QUEUE_CONNECTION=redis
CACHE_DRIVER=redis
SESSION_DRIVER=redis
REDIS_HOST=127.0.0.1

MAIL_MAILER=smtp
MAIL_HOST=smtp.postmarkapp.com
MAIL_PORT=587
MAIL_USERNAME=<postmark-api-token>
MAIL_PASSWORD=<postmark-api-token>
MAIL_FROM_ADDRESS=hello@mindlock.app
MAIL_FROM_NAME="MindLock"
```

### Start the queue worker (Supervisor recommended)

```ini
# /etc/supervisor/conf.d/mindlock-horizon.conf
[program:mindlock-horizon]
command=php /var/www/mindlock_backend/artisan horizon
directory=/var/www/mindlock_backend
autostart=true
autorestart=true
user=www-data
redirect_stderr=true
stdout_logfile=/var/log/mindlock/horizon.log
```

```bash
supervisorctl reread && supervisorctl update && supervisorctl start mindlock-horizon
```

### Scheduled jobs (cron)

Add to server cron (`crontab -e`):

```cron
* * * * * www-data cd /var/www/mindlock_backend && php artisan schedule:run >> /dev/null 2>&1
```

### Nginx config (HTTPS)

```nginx
server {
    listen 443 ssl;
    server_name api.mindlock.app;

    root /var/www/mindlock_backend/public;
    index index.php;

    ssl_certificate /etc/letsencrypt/live/api.mindlock.app/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.mindlock.app/privkey.pem;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location ~ \.php$ {
        fastcgi_pass unix:/var/run/php/php8.2-fpm.sock;
        fastcgi_param SCRIPT_FILENAME $realpath_root$fastcgi_script_name;
        include fastcgi_params;
    }
}
```

---

## 2. Connect Flutter to the Production API

### Step 1 — Update the base URL

Open `lib/core/constants/app_constants.dart` and verify:

```dart
static const String apiBaseUrlProd = 'https://api.mindlock.app/api/v1';
static const String apiBaseUrlDev  = 'http://10.0.2.2:8000/api/v1';
```

`10.0.2.2` is the Android emulator's alias for `localhost`. For a real device during development use your machine's LAN IP (e.g. `http://192.168.1.x:8000/api/v1`).

### Step 2 — Switch the Dio client to production

Open `lib/core/network/api_client.dart` and change:

```dart
// Before (dev)
baseUrl: AppConstants.apiBaseUrlDev,

// After (production)
baseUrl: AppConstants.apiBaseUrlProd,
```

> **Recommended:** Use `--dart-define` to inject the URL at build time so you never have to edit the file:

```bash
# Dev build
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1

# Production build
flutter build appbundle --dart-define=API_BASE_URL=https://api.mindlock.app/api/v1
```

Then in `app_constants.dart`:

```dart
static const String apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://api.mindlock.app/api/v1',
);
```

And in `api_client.dart`:

```dart
baseUrl: AppConstants.apiBaseUrl,
```

### Step 3 — Network security config (already set)

`android/app/src/main/res/xml/network_security_config.xml` already blocks cleartext for everything except `10.0.2.2` and `localhost`. Production HTTPS traffic to `api.mindlock.app` requires no changes.

### Step 4 — Test the connection

```bash
# Run on a real device
flutter run --release --dart-define=API_BASE_URL=https://api.mindlock.app/api/v1
```

Verify:
- Login returns a Sanctum token
- `GET /api/v1/apps/config` returns monitored apps
- `POST /api/v1/sync/usage-logs` returns `200 OK`

---

## 3. Firebase Setup (Push Notifications)

The app uses `firebase_messaging` for push notifications. Without this, the app **will not compile** in release mode.

### Step 1 — Create a Firebase project

1. Go to [console.firebase.google.com](https://console.firebase.google.com)
2. Create project → "MindLock"
3. Add an Android app:
   - Package name: `com.mindlock.app`
   - App nickname: MindLock
   - SHA-1: run `keytool -list -v -keystore <your-keystore>.jks` (after creating keystore in section 4)
4. Download `google-services.json`

### Step 2 — Place the file

```
mindlock_flutter/
└── android/
    └── app/
        └── google-services.json   ← place here
```

### Step 3 — Connect FCM to the Laravel backend

In your Laravel `.env`:

```dotenv
FIREBASE_CREDENTIALS=/var/www/mindlock_backend/storage/firebase-service-account.json
```

Download the Firebase Admin SDK service account JSON from Firebase Console → Project Settings → Service Accounts → Generate new private key. Save it to `storage/firebase-service-account.json`.

### Step 4 — Register device tokens

The Flutter app sends the FCM token to the backend on login. Ensure `POST /api/v1/devices/register` is available (already in the backend routes).

---

## 4. Generate the Release Keystore

A keystore is required to sign the APK/AAB. **Keep this file and its passwords safe — losing it means you can never update the app on Play Store.**

```bash
keytool -genkey -v \
  -keystore mindlock-release.jks \
  -alias mindlock \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000
```

You will be prompted for:
- Keystore password (save this)
- Key alias password (save this)
- Your name, organisation, city, country

Move the keystore to a safe location **outside** the project repo:

```bash
mv mindlock-release.jks ~/.android/mindlock-release.jks
```

> **Never commit the `.jks` file or its passwords to git.**

---

## 5. Configure Signing in Gradle

### Step 1 — Create key.properties

Create `android/key.properties` (already in `.gitignore`):

```properties
storePassword=<your-keystore-password>
keyPassword=<your-key-password>
keyAlias=mindlock
storeFile=/Users/<you>/.android/mindlock-release.jks
```

On Windows use forward slashes or double backslashes:

```properties
storeFile=C:/Users/<you>/.android/mindlock-release.jks
```

### Step 2 — Wire it into build.gradle

Open `android/app/build.gradle` and replace the `signingConfigs` / `buildTypes` block:

```groovy
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystorePropertiesFile.withReader('UTF-8') { reader ->
        keystoreProperties.load(reader)
    }
}

android {
    // ... existing config ...

    signingConfigs {
        release {
            keyAlias     keystoreProperties['keyAlias']
            keyPassword  keystoreProperties['keyPassword']
            storeFile    keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }

    buildTypes {
        release {
            signingConfig    signingConfigs.release   // was signingConfigs.debug
            minifyEnabled    true
            shrinkResources  true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
        debug {
            applicationIdSuffix ".debug"
            versionNameSuffix  "-debug"
        }
    }
}
```

---

## 6. Build the Release AAB

Google Play requires an **Android App Bundle** (`.aab`), not a plain APK.

### Step 1 — Generate Drift/Riverpod/Freezed code

This must be run any time you change a Drift table, Riverpod provider, or Freezed model:

```bash
cd mindlock_flutter
dart run build_runner build --delete-conflicting-outputs
```

### Step 2 — Run tests

```bash
flutter test
```

### Step 3 — Build the bundle

```bash
flutter build appbundle \
  --release \
  --dart-define=API_BASE_URL=https://api.mindlock.app/api/v1
```

Output: `build/app/outputs/bundle/release/app-release.aab`

### Step 4 — (Optional) Build a plain APK for local testing

```bash
flutter build apk \
  --release \
  --dart-define=API_BASE_URL=https://api.mindlock.app/api/v1
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

Install on device:

```bash
adb install build/app/outputs/flutter-apk/app-release.apk
```

### Step 5 — Increment version before every release

In `pubspec.yaml`:

```yaml
version: 1.0.1+2   # format: versionName+versionCode
#                             ^       ^
#                             |       Play Store version code (must increase every upload)
#                             Display version shown to users
```

---

## 7. Google Play Console — First Upload

### Step 1 — Create a developer account

1. Go to [play.google.com/console](https://play.google.com/console)
2. Pay the $25 one-time registration fee
3. Complete identity verification

### Step 2 — Create the app

1. Dashboard → **Create app**
2. App name: `MindLock`
3. Default language: English (United States)
4. App or game: **App**
5. Free or paid: **Free** (or Paid — cannot change later)
6. Accept policies → **Create app**

### Step 3 — Complete the store listing

Navigate to **Grow → Store presence → Main store listing**:

| Field | Value |
|-------|-------|
| App name | MindLock |
| Short description | Take back control of your screen time |
| Full description | (150–4000 chars describing the app) |
| App icon | 512×512 PNG, no alpha |
| Feature graphic | 1024×500 PNG/JPG |
| Screenshots | Min 2, max 8 per device type (phone required) |
| Phone screenshots | At least 2 screenshots at 16:9 or 9:16 |

### Step 4 — Fill in required declarations

- **App content** → Content rating → complete questionnaire
- **App content** → Target audience → set age group
- **App content** → Data safety → declare what data is collected (usage stats, account info, device ID)
- **App content** → Permissions → declare PACKAGE_USAGE_STATS and why it's needed
- **Policy** → declare no ads if applicable

### Step 5 — Set up an internal test track (recommended first)

1. **Release → Testing → Internal testing → Create new release**
2. Upload `app-release.aab`
3. Add testers by email
4. Roll out to internal track

Test thoroughly before promoting to production.

### Step 6 — Promote to Production

1. **Release → Production → Create new release**
2. Upload the same `.aab` (or promote from internal track)
3. Add release notes
4. Set rollout percentage (start at 10–20% recommended)
5. Submit for review

Review typically takes 1–3 days for new apps.

---

## 8. Google Play Console — Subsequent Releases

For every update:

1. Increment `version` in `pubspec.yaml` (versionCode must be higher than previous)
2. Run `dart run build_runner build --delete-conflicting-outputs` if any models changed
3. Run `flutter build appbundle --release --dart-define=API_BASE_URL=https://api.mindlock.app/api/v1`
4. Upload new `.aab` to Play Console → Production → Create new release
5. Write release notes
6. Submit for review (updates typically review in hours)

---

## 9. Environment Variables Reference

### Flutter — compile-time (`--dart-define`)

| Variable | Dev value | Production value |
|----------|-----------|-----------------|
| `API_BASE_URL` | `http://10.0.2.2:8000/api/v1` | `https://api.mindlock.app/api/v1` |

### Flutter — runtime (from `AppConstants`)

| Constant | Purpose |
|----------|---------|
| `connectTimeout` | 30 000 ms — Dio connect timeout |
| `receiveTimeout` | 30 000 ms — Dio receive timeout |
| `entitlementCacheTtlMinutes` | 60 — how long Pro status is cached locally |
| `defaultUsageSyncIntervalMinutes` | 15 — background sync interval |

### Flutter — secure storage keys (`StorageKeys`)

| Key | Stored value |
|-----|-------------|
| `access_token` | Sanctum API token |
| `device_id` | UUID generated on first launch |

### Laravel `.env` production values

| Variable | Notes |
|----------|-------|
| `APP_ENV` | Must be `production` |
| `APP_DEBUG` | Must be `false` |
| `APP_URL` | Full HTTPS URL of the API server |
| `SANCTUM_STATEFUL_DOMAINS` | Your API domain |
| `QUEUE_CONNECTION` | `redis` for Horizon |
| `FIREBASE_CREDENTIALS` | Path to service account JSON |

---

## 10. Pre-Launch Checklist

### Backend

- [ ] `APP_DEBUG=false` in production `.env`
- [ ] HTTPS configured with valid SSL certificate
- [ ] Database migrations applied (`php artisan migrate --force`)
- [ ] Queue worker running (Horizon / Supervisor)
- [ ] Cron job configured for `php artisan schedule:run`
- [ ] Firebase service account JSON placed at `storage/`
- [ ] Rate limiting confirmed on `/api/v1/auth/*` endpoints
- [ ] `php artisan config:cache && route:cache && view:cache` run

### Flutter

- [ ] `dart run build_runner build --delete-conflicting-outputs` completed
- [ ] `API_BASE_URL` points to production (`https://api.mindlock.app/api/v1`)
- [ ] `google-services.json` placed at `android/app/google-services.json`
- [ ] `key.properties` created with release keystore path and passwords
- [ ] `signingConfig signingConfigs.release` set in `build.gradle` (not `.debug`)
- [ ] `pubspec.yaml` version incremented
- [ ] `flutter test` passes
- [ ] `flutter build appbundle --release` completes without errors
- [ ] Manual smoke test on physical Android device (not emulator)
- [ ] Login → apps load → lock trigger → unlock challenge → sync verified in backend DB

### Google Play

- [ ] Developer account created and verified
- [ ] Store listing complete (icon, screenshots, description)
- [ ] Data safety form completed
- [ ] Content rating questionnaire completed
- [ ] PACKAGE_USAGE_STATS permission declaration submitted
- [ ] Internal test track validated by at least 2 testers
- [ ] Release notes written for production release
- [ ] Initial rollout set to 10–20%

---

## Quick Reference — Common Commands

```bash
# Generate all Drift/Riverpod/Freezed code
dart run build_runner build --delete-conflicting-outputs

# Run on connected device (dev)
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1

# Run on connected device (prod API)
flutter run --release --dart-define=API_BASE_URL=https://api.mindlock.app/api/v1

# Build release AAB for Play Store
flutter build appbundle --release --dart-define=API_BASE_URL=https://api.mindlock.app/api/v1

# Build release APK for sideloading
flutter build apk --release --dart-define=API_BASE_URL=https://api.mindlock.app/api/v1

# Install APK on connected device
adb install build/app/outputs/flutter-apk/app-release.apk

# Check signing info of an AAB/APK
apksigner verify --print-certs build/app/outputs/flutter-apk/app-release.apk
```
