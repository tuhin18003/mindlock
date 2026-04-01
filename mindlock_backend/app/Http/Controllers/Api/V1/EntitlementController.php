<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Plan;
use App\Services\EntitlementResolver;
use App\Services\FeatureGateService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class EntitlementController extends Controller
{
    public function __construct(
        private readonly EntitlementResolver $entitlementResolver,
        private readonly FeatureGateService $featureGateService,
    ) {}

    public function current(Request $request): JsonResponse
    {
        $user = $request->user();

        return response()->json([
            'success' => true,
            'data' => [
                'entitlement' => $this->entitlementResolver->getSummary($user),
                'gates'       => $this->featureGateService->getGates($user),
            ],
        ]);
    }

    public function plans(): JsonResponse
    {
        $plans = Plan::where('is_active', true)
            ->orderBy('sort_order')
            ->get(['id', 'slug', 'name', 'description', 'tier', 'billing_cycle', 'price', 'currency', 'trial_days', 'features']);

        return response()->json(['success' => true, 'data' => $plans]);
    }

    public function validateAccess(Request $request): JsonResponse
    {
        $request->validate(['feature' => 'required|string']);

        $user = $request->user();
        $canAccess = $this->featureGateService->canAccess($user, $request->feature);

        return response()->json([
            'success' => true,
            'data' => [
                'feature'    => $request->feature,
                'can_access' => $canAccess,
                'is_pro'     => $this->entitlementResolver->isPro($user),
            ],
        ]);
    }
}
