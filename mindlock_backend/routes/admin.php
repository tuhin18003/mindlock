<?php

use App\Http\Controllers\Admin\AdminAnalyticsController;
use App\Http\Controllers\Admin\ChallengeCategoryController;
use App\Http\Controllers\Admin\ChallengeManagementController;
use App\Http\Controllers\Admin\EntitlementManagementController;
use App\Http\Controllers\Admin\FeatureFlagController;
use App\Http\Controllers\Admin\SupportTicketController;
use App\Http\Controllers\Admin\UserManagementController;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| MindLock Admin API
|--------------------------------------------------------------------------
| All routes require auth:sanctum + role:admin
*/

Route::prefix('admin')->middleware(['auth:sanctum', 'role:admin'])->group(function () {

    // ─── User Management ───────────────────────────────────────────────────
    Route::prefix('users')->group(function () {
        Route::get('/',                   [UserManagementController::class, 'index']);
        Route::get('/{user}',             [UserManagementController::class, 'show']);
        Route::post('/{user}/suspend',    [UserManagementController::class, 'suspend']);
        Route::post('/{user}/restore',    [UserManagementController::class, 'restore']);
    });

    // ─── Entitlement Management ────────────────────────────────────────────
    Route::prefix('entitlements')->group(function () {
        Route::get('/',                               [EntitlementManagementController::class, 'index']);
        Route::get('/user/{user}',                    [EntitlementManagementController::class, 'userHistory']);
        Route::post('/user/{user}/grant-pro',         [EntitlementManagementController::class, 'grantPro']);
        Route::post('/user/{user}/revoke',            [EntitlementManagementController::class, 'revoke']);
    });

    // ─── Analytics ────────────────────────────────────────────────────────
    Route::prefix('analytics')->group(function () {
        Route::get('/overview',      [AdminAnalyticsController::class, 'overview']);
        Route::get('/usage',         [AdminAnalyticsController::class, 'usageAnalytics']);
        Route::get('/unlocks',       [AdminAnalyticsController::class, 'unlockAnalytics']);
        Route::get('/challenges',    [AdminAnalyticsController::class, 'challengeAnalytics']);
        Route::get('/entitlements',  [AdminAnalyticsController::class, 'entitlementAnalytics']);
        Route::get('/risk',          [AdminAnalyticsController::class, 'riskAnalytics']);
    });

    // ─── Challenge Management ──────────────────────────────────────────────
    Route::apiResource('challenges', ChallengeManagementController::class);
    Route::apiResource('challenge-categories', ChallengeCategoryController::class);

    // ─── Feature Flags ─────────────────────────────────────────────────────
    Route::apiResource('feature-flags', FeatureFlagController::class);

    // ─── Support Tickets ──────────────────────────────────────────────────
    Route::prefix('support-tickets')->group(function () {
        Route::get('/',            [SupportTicketController::class, 'index']);
        Route::get('/{ticket}',    [SupportTicketController::class, 'show']);
        Route::put('/{ticket}',    [SupportTicketController::class, 'update']);
    });

    // ─── Audit Log ────────────────────────────────────────────────────────
    Route::get('/audit-log', function (): JsonResponse {
        $logs = \App\Models\AdminAuditLog::with('admin:id,name,email')
            ->orderByDesc('created_at')
            ->paginate(request('per_page', 50));

        return response()->json(['success' => true, 'data' => $logs]);
    });

    // ─── Dashboard Summary (quick stats for admin home) ────────────────────
    Route::get('/dashboard', function (): JsonResponse {
        $today = now()->toDateString();

        return response()->json([
            'success' => true,
            'data'    => [
                'total_users'       => DB::table('users')->where('status', 'active')->count(),
                'pro_users'         => DB::table('entitlements')->where('tier', 'pro')->where('status', 'active')->count(),
                'dau'               => DB::table('device_sessions')->whereDate('last_seen_at', today())->distinct('user_id')->count('user_id'),
                'new_today'         => DB::table('users')->whereDate('created_at', today())->count(),
                'locks_today'       => DB::table('lock_events')->whereDate('locked_at', today())->count(),
                'unlocks_today'     => DB::table('unlock_events')->whereDate('unlocked_at', today())->count(),
                'challenges_today'  => DB::table('challenge_completions')->where('result', 'completed')->whereDate('completed_at', today())->count(),
                'emergencies_today' => DB::table('emergency_unlocks')->whereDate('used_at', today())->count(),
                'open_tickets'      => DB::table('support_tickets')->where('status', 'open')->count(),
            ],
        ]);
    });
});
