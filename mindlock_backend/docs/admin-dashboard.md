# MindLock Admin Dashboard

The admin dashboard is a React 18 SPA served by Laravel at `/admin`. It provides full visibility and control over the MindLock platform — users, Pro entitlements, challenges, analytics, feature flags, and support tickets.

---

## Requirements

| Dependency | Minimum Version |
|---|---|
| PHP | 8.2+ |
| Laravel | 11.x |
| Node.js | 18+ |
| npm | 9+ |
| MySQL / PostgreSQL | 8.0+ / 14+ |
| Redis | 6+ (for queues) |

---

## Installation

### 1. Clone and install PHP dependencies

```bash
cd mindlock_backend
composer install --no-dev --optimize-autoloader
```

### 2. Configure environment

```bash
cp .env.example .env
php artisan key:generate
```

Edit `.env` with your database, Redis, and mail settings:

```env
APP_URL=https://yourdomain.com

DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=mindlock
DB_USERNAME=root
DB_PASSWORD=secret

REDIS_HOST=127.0.0.1
REDIS_PORT=6379

MAIL_MAILER=smtp
MAIL_HOST=smtp.yourprovider.com
MAIL_PORT=587
MAIL_USERNAME=your@email.com
MAIL_PASSWORD=secret
MAIL_FROM_ADDRESS=noreply@yourdomain.com
MAIL_FROM_NAME="MindLock"

QUEUE_CONNECTION=redis
```

### 3. Run migrations and seeders

```bash
php artisan migrate --force
php artisan db:seed
```

The seeder creates:
- Roles: `admin`, `super_admin`, `user`
- Default admin user: `admin@mindlock.app` / `password` *(change immediately)*
- Subscription plans: free, pro_monthly, pro_annual
- Challenge categories and sample challenges

### 4. Install Node dependencies and build the admin SPA

```bash
npm install
npm run build
```

For local development with hot module replacement:

```bash
npm run dev
```

### 5. Create the storage symlink

```bash
php artisan storage:link
```

### 6. Set directory permissions

```bash
chmod -R 775 storage bootstrap/cache
chown -R www-data:www-data storage bootstrap/cache
```

### 7. Start the queue worker (required for notifications and jobs)

```bash
php artisan horizon
```

Or with a basic worker:

```bash
php artisan queue:work redis --queue=default,analytics,aggregation --tries=3
```

---

## Accessing the Admin Panel

Navigate to:

```
https://yourdomain.com/admin
```

Log in with the seeded admin account:

| Field | Value |
|---|---|
| Email | `admin@mindlock.app` |
| Password | `password` |

**Change the password immediately after first login** via the database or by creating a new admin user (see below).

---

## Creating Additional Admin Users

```bash
php artisan tinker
```

```php
$user = \App\Models\User::create([
    'name'              => 'Your Name',
    'email'             => 'you@yourcompany.com',
    'password'          => bcrypt('strong-password'),
    'email_verified_at' => now(),
    'status'            => 'active',
]);

$user->assignRole('admin');
```

---

## Admin Features

### Dashboard
Real-time overview of platform health — total users, DAU, Pro count, daily locks/unlocks/challenges/emergencies, and open support tickets. Charts auto-refresh every 60 seconds.

### User Management (`/admin/users`)
- Search by name or email
- Filter by status (active / suspended) and tier (free / pro)
- View full user profile with 30-day activity breakdown
- **Suspend / Restore** accounts
- Grant or revoke Pro entitlements directly from the user detail page

### Entitlement Management (`/admin/entitlements`)
- View all Pro grants across the platform
- Filter by source, status, tier, and expiry
- **Grant Pro** with configurable source, expiry date, and admin notes
- **Revoke** manually-granted entitlements (subscription-based entitlements must be managed via the billing provider)

Sources available when granting:
| Source | Description |
|---|---|
| `admin_grant` | Manual override |
| `lifetime` | Permanent, no expiry |
| `trial` | Time-limited free trial |
| `coupon` | Coupon code redemption |

### Challenge Management (`/admin/challenges`)
- Full CRUD for challenges and categories
- Toggle active/inactive (deactivating a challenge does not delete it or user completion history)
- Set Pro requirement, difficulty, reward minutes, and duration

### Analytics (`/admin/analytics`)
Six tabbed views:

| Tab | What it shows |
|---|---|
| **Overview** | DAU trend, user growth, free/pro tier split |
| **Usage** | App session trends, top monitored apps |
| **Unlocks** | Unlock events by day and method, emergency unlock trends |
| **Challenges** | Completion trends, top challenges, breakdown by type |
| **Entitlements** | Active Pro over time, Pro by grant source |
| **Risk** | High-risk users (frequent emergency unlocks, high skip rates) |

### Feature Flags (`/admin/feature-flags`)
- Toggle features on/off platform-wide
- Rollout types: `all`, `percentage`, `user_ids`, `tier`
- Full audit trail of every change

### Support Tickets (`/admin/support-tickets`)
- Sorted by priority (urgent first)
- Inline status updates and admin responses
- Resolved tickets automatically record `resolved_at` timestamp

### Audit Log (`/admin/audit-log`)
Immutable log of every admin action — who did what, when, to which resource, with before/after state diffs.

---

## API Authentication

The admin SPA authenticates against the same Sanctum token endpoint used by the mobile app:

```
POST /api/v1/auth/login
```

The token is stored in `localStorage` via Zustand persist. The SPA checks that the authenticated user has the `admin` role — non-admin tokens are rejected at the login screen.

All admin API routes are protected by both `auth:sanctum` and `role:admin` middleware:

```
/api/admin/*
```

---

## Scheduled Jobs

The following commands run automatically when Laravel's scheduler is active. Add this single cron entry on the server:

```
* * * * * cd /path/to/mindlock_backend && php artisan schedule:run >> /dev/null 2>&1
```

| Schedule | Command | Purpose |
|---|---|---|
| Daily at 00:15 | `analytics:aggregate-daily` | Aggregate usage summaries |
| Daily at 00:30 | `scores:compute` | Compute recovery scores |
| Hourly | `entitlements:expire` | Expire stale entitlements + send warnings |
| Weekly (Sunday) | `analytics:prune` | Delete raw events older than 90 days |

---

## Production Checklist

- [ ] Change default admin password
- [ ] Set `APP_ENV=production` and `APP_DEBUG=false`
- [ ] Configure a real mail driver (not `log`)
- [ ] Set up Redis and run Horizon as a supervised process
- [ ] Configure the cron scheduler
- [ ] Set `SESSION_SECURE_COOKIE=true` behind HTTPS
- [ ] Run `php artisan config:cache && php artisan route:cache && php artisan view:cache`
- [ ] Set `SANCTUM_STATEFUL_DOMAINS` to your admin domain if using cookie-based auth

---

## Tech Stack

| Layer | Technology |
|---|---|
| Backend framework | Laravel 11 |
| Authentication | Laravel Sanctum |
| Roles & Permissions | Spatie Laravel Permission |
| Queue / Workers | Laravel Horizon + Redis |
| Admin SPA | React 18 + Vite |
| State management | Zustand |
| Data fetching | TanStack Query v5 |
| Charts | Recharts |
| UI components | Tailwind CSS + Headless UI |
| Icons | Lucide React |
