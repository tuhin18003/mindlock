<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\AppLimit;
use App\Models\MonitoredApp;
use App\Services\EntitlementResolver;
use App\Services\FeatureGateService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AppsController extends Controller
{
    public function __construct(
        private readonly EntitlementResolver $entitlementResolver,
        private readonly FeatureGateService  $featureGateService,
    ) {}

    /**
     * GET /api/v1/apps
     * Returns the user's monitored apps with their limits.
     */
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();

        $monitoredApps = MonitoredApp::where('user_id', $user->id)->get();
        $limits        = AppLimit::where('user_id', $user->id)->get()->keyBy('package_name');

        $data = $monitoredApps->map(fn($app) => [
            'package_name'        => $app->package_name,
            'app_name'            => $app->app_name,
            'category'            => $app->category,
            'is_tracked'          => $app->is_tracked,
            'is_locked'           => $app->is_locked,
            'strict_mode'         => $app->strict_mode,
            'daily_limit_minutes' => $limits->get($app->package_name)?->daily_limit_minutes,
            'is_active'           => $limits->get($app->package_name)?->is_active ?? false,
        ]);

        return response()->json(['success' => true, 'data' => $data]);
    }

    /**
     * GET /api/v1/apps/limits
     * Returns the full limits configuration — what gets synced down to device on app open.
     */
    public function limits(Request $request): JsonResponse
    {
        $user = $request->user();
        $isPro = $this->entitlementResolver->isPro($user);

        $limits = AppLimit::where('user_id', $user->id)
            ->where('is_active', true)
            ->get(['package_name', 'daily_limit_minutes', 'weekday_limit_minutes', 'weekend_limit_minutes']);

        $lockedApps = MonitoredApp::where('user_id', $user->id)
            ->where('is_locked', true)
            ->get(['package_name', 'strict_mode']);

        return response()->json([
            'success' => true,
            'data'    => [
                'limits'      => $limits,
                'locked_apps' => $lockedApps,
                'strict_mode_available' => $isPro,
            ],
        ]);
    }

    /**
     * PUT /api/v1/apps/{packageName}/limit
     * Set or update a daily limit for an app.
     */
    public function setLimit(Request $request, string $packageName): JsonResponse
    {
        $user  = $request->user();
        $isPro = $this->entitlementResolver->isPro($user);

        $validated = $request->validate([
            'daily_limit_minutes'   => 'required|integer|min:0|max:1440',
            'weekday_limit_minutes' => 'nullable|integer|min:0|max:1440',
            'weekend_limit_minutes' => 'nullable|integer|min:0|max:1440',
            'is_active'             => 'boolean',
        ]);

        // Weekday/weekend split is a Pro feature
        if ((!$isPro) && ($validated['weekday_limit_minutes'] || $validated['weekend_limit_minutes'])) {
            return response()->json([
                'success'          => false,
                'message'          => 'Custom weekday/weekend limits require Pro.',
                'upgrade_required' => true,
            ], 403);
        }

        // Free tier: max 5 monitored apps
        if (!$isPro) {
            $existing = AppLimit::where('user_id', $user->id)->where('is_active', true)->count();
            $hasThisApp = AppLimit::where('user_id', $user->id)->where('package_name', $packageName)->exists();
            if (!$hasThisApp && $existing >= \App\Services\FeatureGateService::FREE_MONITORED_APPS_LIMIT) {
                return response()->json([
                    'success'          => false,
                    'message'          => 'Free plan allows monitoring up to 5 apps.',
                    'upgrade_required' => true,
                ], 403);
            }
        }

        $limit = AppLimit::updateOrCreate(
            ['user_id' => $user->id, 'package_name' => $packageName],
            $validated
        );

        return response()->json(['success' => true, 'data' => $limit]);
    }

    /**
     * DELETE /api/v1/apps/{packageName}/limit
     * Remove a daily limit.
     */
    public function removeLimit(Request $request, string $packageName): JsonResponse
    {
        AppLimit::where('user_id', $request->user()->id)
            ->where('package_name', $packageName)
            ->update(['is_active' => false]);

        return response()->json(['success' => true]);
    }

    /**
     * PUT /api/v1/apps/{packageName}/lock
     * Toggle lock state.
     */
    public function toggleLock(Request $request, string $packageName): JsonResponse
    {
        $validated = $request->validate([
            'is_locked'   => 'required|boolean',
            'strict_mode' => 'nullable|boolean',
            'app_name'    => 'nullable|string',
        ]);

        $user  = $request->user();
        $isPro = $this->entitlementResolver->isPro($user);

        // Strict mode is Pro-only
        if (!$isPro && ($validated['strict_mode'] ?? false)) {
            return response()->json([
                'success'          => false,
                'message'          => 'Strict mode requires Pro.',
                'upgrade_required' => true,
            ], 403);
        }

        MonitoredApp::updateOrCreate(
            ['user_id' => $user->id, 'package_name' => $packageName],
            [
                'app_name'    => $validated['app_name'] ?? $packageName,
                'is_locked'   => $validated['is_locked'],
                'is_tracked'  => true,
                'strict_mode' => $validated['strict_mode'] ?? false,
            ]
        );

        return response()->json(['success' => true]);
    }

    /**
     * GET /api/v1/apps/config
     * Full config dump for device — called on app launch and after sync.
     * Returns everything the device needs to operate offline.
     */
    public function deviceConfig(Request $request): JsonResponse
    {
        $user  = $request->user();
        $isPro = $this->entitlementResolver->isPro($user);

        $limits = AppLimit::where('user_id', $user->id)->where('is_active', true)->get();
        $monitored = MonitoredApp::where('user_id', $user->id)->get();

        return response()->json([
            'success' => true,
            'data'    => [
                'limits'        => $limits,
                'monitored'     => $monitored,
                'is_pro'        => $isPro,
                'gates'         => $this->featureGateService->getGates($user),
                'config_version'=> now()->timestamp,
            ],
        ]);
    }
}
