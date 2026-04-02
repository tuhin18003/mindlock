<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Resources\User\UserProfileResource;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rule;

class UserController extends Controller
{
    /**
     * GET /api/v1/user
     */
    public function profile(Request $request): JsonResponse
    {
        $user = $request->user()->load([
            'notificationPreferences',
            'streak',
            'activeEntitlement',
        ]);

        return response()->json([
            'success' => true,
            'data'    => new UserProfileResource($user),
        ]);
    }

    /**
     * PUT /api/v1/user
     */
    public function update(Request $request): JsonResponse
    {
        $user = $request->user();

        $validated = $request->validate([
            'name'     => 'sometimes|string|max:100',
            'timezone' => 'sometimes|string|timezone',
            'locale'   => 'sometimes|string|max:10',
        ]);

        $user->update($validated);

        return response()->json([
            'success' => true,
            'data'    => new UserProfileResource($user->fresh()),
        ]);
    }

    /**
     * PUT /api/v1/user/goals
     */
    public function updateGoals(Request $request): JsonResponse
    {
        // Goals stored in user metadata / prefs — placeholder for future goal model
        $request->validate([
            'daily_screen_limit_minutes'   => 'nullable|integer|min:0|max:1440',
            'weekly_focus_goal_minutes'    => 'nullable|integer|min:0',
            'daily_challenge_goal'         => 'nullable|integer|min:0|max:20',
        ]);

        // For now, return success — goals model can be added in Phase 17
        return response()->json([
            'success' => true,
            'message' => 'Goals updated.',
            'data'    => $request->only(['daily_screen_limit_minutes', 'weekly_focus_goal_minutes', 'daily_challenge_goal']),
        ]);
    }

    /**
     * PUT /api/v1/user/notification-preferences
     */
    public function updateNotificationPreferences(Request $request): JsonResponse
    {
        $user = $request->user();

        $validated = $request->validate([
            'daily_summary'        => 'boolean',
            'streak_reminders'     => 'boolean',
            'weekly_report'        => 'boolean',
            'lock_triggered'       => 'boolean',
            'challenge_reminders'  => 'boolean',
            'pro_expiry_reminder'  => 'boolean',
            'quiet_hours_start'    => 'nullable|date_format:H:i',
            'quiet_hours_end'      => 'nullable|date_format:H:i',
        ]);

        $prefs = $user->notificationPreferences()->firstOrCreate(['user_id' => $user->id]);
        $prefs->update($validated);

        return response()->json(['success' => true, 'data' => $prefs->fresh()]);
    }

    /**
     * POST /api/v1/user/avatar
     */
    public function uploadAvatar(Request $request): JsonResponse
    {
        $request->validate([
            'avatar' => 'required|image|mimes:jpg,jpeg,png,webp|max:2048',
        ]);

        $user = $request->user();
        $path = $request->file('avatar')->store("avatars/{$user->id}", 'public');

        $user->update(['avatar' => $path]);

        return response()->json([
            'success' => true,
            'data'    => ['avatar_url' => asset("storage/{$path}")],
        ]);
    }
}
