<?php

namespace App\Providers;

use App\Services\AnalyticsAggregationService;
use App\Services\EntitlementResolver;
use App\Services\FeatureGateService;
use App\Services\RecoveryScoreService;
use App\Services\UsageSyncService;
use Illuminate\Cache\RateLimiting\Limit;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Support\Facades\Route;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        // Bind services as singletons so they share state within a request
        $this->app->singleton(EntitlementResolver::class);

        $this->app->singleton(FeatureGateService::class, fn($app) =>
            new FeatureGateService($app->make(EntitlementResolver::class))
        );

        $this->app->singleton(UsageSyncService::class);
        $this->app->singleton(RecoveryScoreService::class);
        $this->app->singleton(AnalyticsAggregationService::class);
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        $this->configureRateLimiting();
        $this->enforceMorphMap();
    }

    protected function configureRateLimiting(): void
    {
        // Default API: 60 req/min per user
        RateLimiter::for('api', function (Request $request) {
            return Limit::perMinute(60)->by(
                $request->user()?->id ?: $request->ip()
            );
        });

        // Auth endpoints: 10 attempts per minute per IP
        RateLimiter::for('auth', function (Request $request) {
            return Limit::perMinute(10)->by($request->ip());
        });

        // Analytics ingest: 120 req/min (higher — batched events)
        RateLimiter::for('analytics', function (Request $request) {
            return Limit::perMinute(120)->by(
                $request->user()?->id ?: $request->ip()
            );
        });
    }

    protected function enforceMorphMap(): void
    {
        \Illuminate\Database\Eloquent\Relations\Relation::morphMap([
            'user'         => \App\Models\User::class,
            'challenge'    => \App\Models\Challenge::class,
            'entitlement'  => \App\Models\Entitlement::class,
            'feature_flag' => \App\Models\FeatureFlag::class,
        ]);
    }
}
