# MindLock Architecture Document

## System Overview

MindLock is a premium digital discipline app with:
- Flutter mobile client (Android-first, iOS-ready)
- Laravel REST API backend
- Laravel admin dashboard
- Redis-backed queue + cache
- MySQL database

---

## Flutter Architecture

### Pattern
Clean Architecture with Riverpod (feature-first)

```
lib/
├── core/               # App-wide utilities (theme, errors, network, constants)
├── config/             # App configuration
├── routes/             # GoRouter setup + guards
├── shared/             # Reusable widgets (MlButton, MlTextField, ProGate)
├── services/           # Platform-agnostic services
│   ├── tracking/       # UsageTrackerService — local usage engine
│   ├── sync/           # SyncService — backend sync
│   ├── analytics/      # AnalyticsService — event tracking
│   ├── entitlement/    # EntitlementService — feature gating
│   ├── platform/       # AppUsageBridge — Android native channel
│   └── storage/        # SecureStorageService, PrefsService
├── data/
│   ├── local/          # Drift DB + DAOs
│   └── remote/         # Dio API client
├── domain/             # Entities + use case interfaces
└── features/           # Feature modules (each has data/domain/presentation)
    ├── auth/
    ├── onboarding/
    ├── dashboard/
    ├── apps/
    ├── locks/          # ★ Core — lock screen + intervention flow
    ├── challenges/
    ├── history/
    ├── settings/
    ├── subscription/   # Paywall
    ├── analytics/
    └── account/
```

### Offline-First Architecture
1. All behavior events written to local Drift DB first
2. SyncService uploads pending records when online
3. EntitlementService caches server response with TTL
4. Lock/unlock decisions made entirely locally (no network required)

### Key Services
| Service | Responsibility |
|---|---|
| `UsageTrackerService` | Read usage from Android, write to local DB, check limits |
| `SyncService` | Upload pending local events to backend |
| `EntitlementService` | Cache + expose Pro access status |
| `AnalyticsService` | Track product events locally, flush to backend |
| `AppUsageBridge` | Platform channel abstraction for Android native |

---

## Laravel Architecture

### Pattern
Service-Repository pattern with thin controllers

```
app/
├── Http/
│   ├── Controllers/Api/V1/    # Mobile API (Sanctum auth)
│   ├── Controllers/Admin/     # Admin API (role:admin)
│   ├── Requests/              # Form Request validation
│   ├── Resources/             # API response formatting
│   └── Middleware/
├── Models/                    # Eloquent models
├── Services/                  # Business logic
├── Repositories/              # Data access abstraction
├── Actions/                   # Single-action classes
├── Policies/                  # Authorization
├── Enums/                     # Status enums
├── Jobs/                      # Async background work
├── Events/ Listeners/         # Event-driven patterns
├── Notifications/             # Push + email notifications
└── Support/                   # Helpers
```

### Core Services
| Service | Responsibility |
|---|---|
| `EntitlementResolver` | ★ Single source of truth for Pro access |
| `FeatureGateService` | Feature flag + Pro gate checks |
| `UsageSyncService` | Idempotent sync of device usage data |
| `AnalyticsAggregationService` | Ingest events + aggregate summaries |
| `RecoveryScoreService` | Compute daily recovery score (0–100) |

### Pro Access Architecture
```
Admin grants/revokes  ──┐
Billing subscription  ──┤──► Entitlement table ──► EntitlementResolver.isPro()
Trial / coupon        ──┘         │                        │
Lifetime grant        ──────────►─┘              FeatureGateService.getGates()
                                                           │
                                                  Mobile API /entitlement/current
                                                           │
                                              EntitlementService (Flutter cache)
                                                           │
                                              MobileFeature.canAccess() / ProGate widget
```

---

## Database Design Principles

1. **Entitlements are separate from billing** — `entitlements` table is the authority
2. **Offline-first events** — `local_event_id` (UUID) ensures idempotent sync
3. **Analytics are append-only** — raw events → daily aggregations → user summaries
4. **Soft deletes on users** — never hard delete user data
5. **All sync operations use upsert** — safe to re-send from device

---

## API Contract

All mobile APIs at `/api/v1/`
Admin APIs at `/api/admin/` (requires `role:admin`)

### Request Headers (all authenticated requests)
```
Authorization: Bearer {token}
X-Device-ID: {uuid}
X-Platform: android|ios
X-App-Version: 1.0.0
X-Timezone: America/New_York
```

---

## Build Phase Map

| Phase | What |
|---|---|
| 1 | Architecture + project setup ✓ |
| 2 | Database schema + migrations ✓ |
| 3 | Backend core services ✓ |
| 4 | API contract (auth, sync, entitlement, analytics) ✓ |
| 5 | Flutter app shell + theme + routing ✓ |
| 6 | Auth flow end-to-end |
| 7 | Entitlement + Pro access (backend + Flutter) ✓ |
| 8 | App selection + limits |
| 9 | Usage tracking + local state engine ✓ |
| 10 | Lock screen + intervention flow ✓ |
| 11 | Dashboard + value display ✓ |
| 12 | History + reports |
| 13 | Analytics event tracking ✓ |
| 14 | Admin dashboard core ✓ |
| 15 | Admin analytics pages ✓ |
| 16 | Billing + monetization (paywall built ✓, billing SDK pending) |
| 17 | Recovery Score ✓, mood tracking, adaptive challenges |
| 18 | Polish + motion + empty states |
| 19 | Testing + QA ✓ (tests written) |
| 20 | Launch readiness |

---

## Recovery Score Formula (0–100)

| Factor | Points |
|---|---|
| Recovered time / screen time ratio | 0–30 |
| Challenge completions today | 0–20 (5pts each, max 4) |
| Emergency unlock discipline | 0–20 (−10 per emergency) |
| Low relock rate | 0–15 (−5 per relock) |
| Streak maintained | 0–15 |

---

## Important Rules

1. **Never check `isPro` inline** — always use `EntitlementService.canAccess(feature)` in Flutter
2. **Never trust local Pro state for billing** — backend validates all purchases
3. **All lock decisions are local** — works offline
4. **Analytics events are fire-and-forget** — never block UI on analytics
5. **Admin grants are audited** — every `AdminAuditLog` entry is immutable
