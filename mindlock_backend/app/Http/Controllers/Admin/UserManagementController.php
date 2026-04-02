<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Http\Resources\Admin\AdminUserResource;
use App\Models\AdminAuditLog;
use App\Models\User;
use App\Services\EntitlementResolver;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class UserManagementController extends Controller
{
    public function __construct(
        private readonly EntitlementResolver $entitlementResolver,
    ) {}

    public function index(Request $request): JsonResponse
    {
        $users = User::with(['activeEntitlement', 'streak'])
            ->when($request->search, fn($q) => $q->where('email', 'like', "%{$request->search}%")
                ->orWhere('name', 'like', "%{$request->search}%"))
            ->when($request->status, fn($q) => $q->where('status', $request->status))
            ->when($request->tier, fn($q) => $q->whereHas('activeEntitlement', fn($e) => $e->where('tier', $request->tier)))
            ->orderByDesc('created_at')
            ->paginate($request->per_page ?? 25);

        return response()->json(['success' => true, 'data' => AdminUserResource::collection($users)]);
    }

    public function show(User $user): JsonResponse
    {
        $user->load(['activeEntitlement', 'streak', 'notificationPreferences', 'behaviorProfile', 'deviceSessions']);

        $recentActivity = [
            'lock_events_30d'  => $user->lockEvents()->where('locked_at', '>=', now()->subDays(30))->count(),
            'unlock_events_30d'=> $user->unlockEvents()->where('unlocked_at', '>=', now()->subDays(30))->count(),
            'challenge_completions_30d' => $user->challengeCompletions()
                ->where('result', 'completed')
                ->where('completed_at', '>=', now()->subDays(30))
                ->count(),
            'emergency_unlocks_30d' => $user->emergencyUnlocks()->where('used_at', '>=', now()->subDays(30))->count(),
        ];

        return response()->json([
            'success' => true,
            'data' => [
                'user'             => $user,
                'entitlement'      => $this->entitlementResolver->getSummary($user),
                'recent_activity'  => $recentActivity,
            ],
        ]);
    }

    public function suspend(Request $request, User $user): JsonResponse
    {
        $request->validate(['reason' => 'nullable|string|max:500']);

        $user->update(['status' => 'suspended']);

        AdminAuditLog::create([
            'admin_id'    => auth()->id(),
            'action'      => 'suspend_user',
            'target_type' => 'user',
            'target_id'   => $user->id,
            'after_state' => ['reason' => $request->reason],
            'ip_address'  => $request->ip(),
        ]);

        return response()->json(['success' => true, 'message' => "User {$user->email} suspended."]);
    }

    public function restore(Request $request, User $user): JsonResponse
    {
        $user->update(['status' => 'active']);

        AdminAuditLog::create([
            'admin_id'    => auth()->id(),
            'action'      => 'restore_user',
            'target_type' => 'user',
            'target_id'   => $user->id,
            'ip_address'  => $request->ip(),
        ]);

        return response()->json(['success' => true, 'message' => "User {$user->email} restored."]);
    }
}
