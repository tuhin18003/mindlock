<?php

use App\Http\Controllers\Admin\AdminAnalyticsController;
use App\Http\Controllers\Admin\EntitlementManagementController;
use App\Http\Controllers\Admin\UserManagementController;
use App\Http\Controllers\Admin\ChallengeManagementController;
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
        Route::get('/overview',    [AdminAnalyticsController::class, 'overview']);
        Route::get('/usage',       [AdminAnalyticsController::class, 'usageAnalytics']);
        Route::get('/unlocks',     [AdminAnalyticsController::class, 'unlockAnalytics']);
        Route::get('/challenges',  [AdminAnalyticsController::class, 'challengeAnalytics']);
    });

    // ─── Challenge Management ──────────────────────────────────────────────
    Route::apiResource('challenges', ChallengeManagementController::class);
    Route::apiResource('challenge-categories', \App\Http\Controllers\Admin\ChallengeCategoryController::class);

    // ─── Feature Flags ─────────────────────────────────────────────────────
    Route::apiResource('feature-flags', \App\Http\Controllers\Admin\FeatureFlagController::class);
});
