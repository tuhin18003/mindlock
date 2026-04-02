# MindLock Launch Readiness Checklist

## Backend
- [ ] Production `.env` configured (APP_ENV=production, APP_DEBUG=false)
- [ ] Database migrations run on production
- [ ] Seeders run (plans, challenges, admin user)
- [ ] Redis configured and queue workers running (Horizon)
- [ ] Scheduler running (`php artisan schedule:work`)
- [ ] API rate limiting configured
- [ ] CORS configured for mobile app domains
- [ ] Sanctum stateful domains set
- [ ] SSL certificate installed
- [ ] Database backups configured
- [ ] Log monitoring set up (Sentry/Bugsnag)
- [ ] Health check endpoint `/api/health` responding
- [ ] Admin user credentials changed from seeder defaults
- [ ] All admin routes tested end-to-end

## Flutter
- [ ] `AppConstants.apiBaseUrlProd` correct
- [ ] Firebase project created + `google-services.json` added
- [ ] Android keystore created and configured in `build.gradle`
- [ ] App icons set (all densities)
- [ ] Splash screen configured
- [ ] Android permissions in `AndroidManifest.xml`:
  - [ ] `PACKAGE_USAGE_STATS`
  - [ ] `RECEIVE_BOOT_COMPLETED`
  - [ ] `FOREGROUND_SERVICE`
  - [ ] `POST_NOTIFICATIONS` (API 33+)
- [ ] `minSdkVersion` set to 24+ (Android 7)
- [ ] `targetSdkVersion` set to 34
- [ ] App versioning (`versionCode` + `versionName`)
- [ ] Release build tested on real device
- [ ] Lock screen behavior tested with real usage stats
- [ ] Offline mode tested (airplane mode + usage tracking)
- [ ] Sync tested after coming back online
- [ ] Entitlement cache TTL tested

## Analytics
- [ ] All `AnalyticsEvent` values tracked in at least one flow
- [ ] Analytics flush confirmed working in production
- [ ] Paywall events firing correctly
- [ ] Onboarding funnel events complete

## Security
- [ ] API tokens have appropriate expiry
- [ ] Admin routes require `role:admin` middleware
- [ ] Input validation on all sync endpoints
- [ ] No sensitive data in analytics payloads
- [ ] Emergency unlock rate-limiting in place
- [ ] SQL injection protection (Eloquent only — no raw queries with user input)

## Legal / Store
- [ ] Privacy policy URL set in app
- [ ] Terms of service URL set in app
- [ ] App store listing prepared
- [ ] Screenshot assets prepared (lock screen, dashboard, paywall)
- [ ] Content rating questionnaire completed
- [ ] IAP products created in Google Play Console
- [ ] IAP products created in App Store Connect

## QA
- [ ] Auth flow: register → onboard → lock → challenge → unlock
- [ ] Pro grant via admin: grant → app shows Pro → revoke → app shows Free
- [ ] Offline lock: disable network → trigger lock → complete challenge → re-enable → sync
- [ ] Paywall: tap upgrade → correct plan selected → trial period shows
- [ ] Streak: complete challenge → verify streak increments
- [ ] Recovery score: computed after unlock events sync
