<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\AdminAuditLog;
use App\Models\User;
use App\Services\EntitlementResolver;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;

class EntitlementManagementController extends Controller
{
    public function __construct(
        private readonly EntitlementResolver $resolver,
    ) {}

    /**
     * GET /admin/entitlements — list all active entitlements with filters
     */
    public function index(Request $request): JsonResponse
    {
        $query = \App\Models\Entitlement::with(['user:id,name,email,created_at', 'plan:id,name,slug'])
            ->when($request->tier, fn($q) => $q->where('tier', $request->tier))
            ->when($request->status, fn($q) => $q->where('status', $request->status))
            ->when($request->source, fn($q) => $q->where('source', $request->source))
            ->when($request->search, fn($q) => $q->whereHas('user', fn($u) => $u->where('email', 'like', "%{$request->search}%")))
            ->orderByDesc('created_at')
            ->paginate($request->per_page ?? 25);

        return response()->json(['success' => true, 'data' => $query]);
    }

    /**
     * POST /admin/users/{user}/entitlements/grant-pro
     */
    public function grantPro(Request $request, User $user): JsonResponse
    {
        $request->validate([
            'source'      => 'required|in:admin_grant,lifetime,trial,coupon',
            'expires_at'  => 'nullable|date|after:now',
            'notes'       => 'nullable|string|max:500',
        ]);

        $expiresAt = $request->expires_at ? Carbon::parse($request->expires_at) : null;

        if ($request->source === 'lifetime') {
            $entitlement = $this->resolver->grantLifetime($user, auth()->id(), $request->notes);
        } else {
            $entitlement = $this->resolver->grant(
                user: $user,
                source: $request->source,
                expiresAt: $expiresAt,
                grantedBy: auth()->id(),
                notes: $request->notes,
            );
        }

        $this->auditLog('grant_pro', $user, [
            'source'     => $request->source,
            'expires_at' => $expiresAt?->toIso8601String(),
            'notes'      => $request->notes,
        ]);

        return response()->json([
            'success' => true,
            'data'    => $entitlement->fresh(['user', 'plan']),
            'message' => "Pro access granted to {$user->email}.",
        ]);
    }

    /**
     * POST /admin/users/{user}/entitlements/revoke
     */
    public function revoke(Request $request, User $user): JsonResponse
    {
        $request->validate(['notes' => 'nullable|string|max:500']);

        $this->resolver->revoke($user, auth()->id(), $request->notes);

        $this->auditLog('revoke_pro', $user, ['notes' => $request->notes]);

        return response()->json([
            'success' => true,
            'message' => "Pro access revoked for {$user->email}.",
        ]);
    }

    /**
     * GET /admin/users/{user}/entitlements — user's entitlement history
     */
    public function userHistory(User $user): JsonResponse
    {
        $entitlements = $user->entitlements()
            ->with(['plan:id,name,slug', 'histories'])
            ->orderByDesc('created_at')
            ->get();

        return response()->json([
            'success' => true,
            'data'    => [
                'current_summary' => $this->resolver->getSummary($user),
                'history'         => $entitlements,
            ],
        ]);
    }

    private function auditLog(string $action, User $target, array $metadata = []): void
    {
        AdminAuditLog::create([
            'admin_id'    => auth()->id(),
            'action'      => $action,
            'target_type' => 'user',
            'target_id'   => $target->id,
            'after_state' => $metadata,
            'ip_address'  => request()->ip(),
        ]);
    }
}
