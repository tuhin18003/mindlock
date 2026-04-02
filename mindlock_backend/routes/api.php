<?php

use App\Http\Controllers\Api\V1\AnalyticsController;
use App\Http\Controllers\Api\V1\AppsController;
use App\Http\Controllers\Api\V1\AuthController;
use App\Http\Controllers\Api\V1\ChallengesController;
use App\Http\Controllers\Api\V1\DashboardController;
use App\Http\Controllers\Api\V1\EntitlementController;
use App\Http\Controllers\Api\V1\HistoryController;
use App\Http\Controllers\Api\V1\SyncController;
use App\Http\Controllers\Api\V1\UserController;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| MindLock API v1
|--------------------------------------------------------------------------
*/

Route::prefix('v1')->group(function () {

    // ─── Public (unauthenticated) ──────────────────────────────────────────
    Route::prefix('auth')->group(function () {
        Route::post('/register',        [AuthController::class, 'register']);
        Route::post('/login',           [AuthController::class, 'login']);
        Route::post('/forgot-password', [AuthController::class, 'forgotPassword']);
        Route::post('/reset-password',  [AuthController::class, 'resetPassword']);
    });

    Route::get('/plans', [EntitlementController::class, 'plans']);

    // ─── Authenticated ─────────────────────────────────────────────────────
    Route::middleware('auth:sanctum')->group(function () {

        // Auth
        Route::post('/auth/logout', [AuthController::class, 'logout']);
        Route::get('/auth/me',      [AuthController::class, 'me']);

        // User / Profile
        Route::prefix('user')->group(function () {
            Route::get('/',                       [UserController::class, 'profile']);
            Route::put('/',                       [UserController::class, 'update']);
            Route::put('/goals',                  [UserController::class, 'updateGoals']);
            Route::put('/notification-preferences', [UserController::class, 'updateNotificationPreferences']);
            Route::post('/avatar',                [UserController::class, 'uploadAvatar']);
        });

        // Entitlements
        Route::prefix('entitlement')->group(function () {
            Route::get('/',           [EntitlementController::class, 'current']);
            Route::post('/validate',  [EntitlementController::class, 'validateAccess']);
        });

        // Dashboard
        Route::prefix('dashboard')->group(function () {
            Route::get('/today',   [DashboardController::class, 'today']);
            Route::get('/weekly',  [DashboardController::class, 'weekly']);
            Route::get('/monthly', [DashboardController::class, 'monthly']);
            Route::get('/score',   [DashboardController::class, 'recoveryScore']);
        });

        // Sync
        Route::prefix('sync')->group(function () {
            Route::post('/monitored-apps',       [SyncController::class, 'syncMonitoredApps']);
            Route::post('/usage-logs',           [SyncController::class, 'syncUsageLogs']);
            Route::post('/lock-events',          [SyncController::class, 'syncLockEvents']);
            Route::post('/unlock-events',        [SyncController::class, 'syncUnlockEvents']);
            Route::post('/challenge-completions',[SyncController::class, 'syncChallengeCompletions']);
            Route::get('/today-summary',         [SyncController::class, 'todaySummary']);
        });

        // Analytics event ingest
        Route::post('/analytics/events', [AnalyticsController::class, 'ingest']);

        // Challenges
        Route::prefix('challenges')->group(function () {
            Route::get('/',                  [ChallengesController::class, 'index']);
            Route::get('/categories',        [ChallengesController::class, 'categories']);
            Route::get('/for-intervention',  [ChallengesController::class, 'forIntervention']);
            Route::get('/{challenge}',       [ChallengesController::class, 'show']);
        });

        // Apps / Limits configuration
        Route::prefix('apps')->group(function () {
            Route::get('/',                           [AppsController::class, 'index']);
            Route::get('/limits',                     [AppsController::class, 'limits']);
            Route::get('/config',                     [AppsController::class, 'deviceConfig']);
            Route::put('/{packageName}/limit',        [AppsController::class, 'setLimit'])
                ->where('packageName', '.+');
            Route::delete('/{packageName}/limit',     [AppsController::class, 'removeLimit'])
                ->where('packageName', '.+');
            Route::put('/{packageName}/lock',         [AppsController::class, 'toggleLock'])
                ->where('packageName', '.+');
        });

        // History
        Route::prefix('history')->group(function () {
            Route::get('/activity',          [HistoryController::class, 'activity']);
            Route::get('/locks',             [HistoryController::class, 'locks']);
            Route::get('/challenges',        [HistoryController::class, 'challenges']);
            Route::get('/focus',             [HistoryController::class, 'focus']);
            Route::get('/emergency-unlocks', [HistoryController::class, 'emergencyUnlocks']);
            Route::get('/stats',             [HistoryController::class, 'stats']);
        });
    });
});
