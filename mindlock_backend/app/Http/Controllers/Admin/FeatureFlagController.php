<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\AdminAuditLog;
use App\Models\FeatureFlag;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class FeatureFlagController extends Controller
{
    /**
     * GET /admin/feature-flags
     */
    public function index(): JsonResponse
    {
        $flags = FeatureFlag::orderBy('key')->get();

        return response()->json(['success' => true, 'data' => $flags]);
    }

    /**
     * POST /admin/feature-flags
     */
    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'key'                 => 'required|string|unique:feature_flags,key|regex:/^[a-z_]+$/',
            'name'                => 'required|string|max:100',
            'description'         => 'nullable|string',
            'is_enabled'          => 'boolean',
            'rollout_type'        => 'required|in:everyone,pro_only,percentage,user_list',
            'rollout_percentage'  => 'integer|min:0|max:100',
            'user_ids'            => 'nullable|array',
            'user_ids.*'          => 'integer|exists:users,id',
        ]);

        $flag = FeatureFlag::create($validated);

        $this->auditLog('create_feature_flag', $flag->id, [], $validated);

        return response()->json(['success' => true, 'data' => $flag], 201);
    }

    /**
     * GET /admin/feature-flags/{flag}
     */
    public function show(FeatureFlag $featureFlag): JsonResponse
    {
        return response()->json(['success' => true, 'data' => $featureFlag]);
    }

    /**
     * PUT /admin/feature-flags/{flag}
     */
    public function update(Request $request, FeatureFlag $featureFlag): JsonResponse
    {
        $validated = $request->validate([
            'name'               => 'sometimes|string|max:100',
            'description'        => 'nullable|string',
            'is_enabled'         => 'boolean',
            'rollout_type'       => 'sometimes|in:everyone,pro_only,percentage,user_list',
            'rollout_percentage' => 'integer|min:0|max:100',
            'user_ids'           => 'nullable|array',
            'user_ids.*'         => 'integer|exists:users,id',
        ]);

        $before = $featureFlag->toArray();
        $featureFlag->update($validated);

        $this->auditLog('update_feature_flag', $featureFlag->id, $before, $validated);

        return response()->json(['success' => true, 'data' => $featureFlag->fresh()]);
    }

    /**
     * DELETE /admin/feature-flags/{flag}
     */
    public function destroy(FeatureFlag $featureFlag): JsonResponse
    {
        $this->auditLog('delete_feature_flag', $featureFlag->id, $featureFlag->toArray(), []);
        $featureFlag->delete();

        return response()->json(['success' => true, 'message' => "Feature flag '{$featureFlag->key}' deleted."]);
    }

    private function auditLog(string $action, int $targetId, array $before, array $after): void
    {
        AdminAuditLog::create([
            'admin_id'    => auth()->id(),
            'action'      => $action,
            'target_type' => 'feature_flag',
            'target_id'   => $targetId,
            'before_state'=> $before,
            'after_state' => $after,
            'ip_address'  => request()->ip(),
        ]);
    }
}
