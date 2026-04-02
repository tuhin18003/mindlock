<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Challenge;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ChallengeManagementController extends Controller
{
    /**
     * GET /admin/challenges
     */
    public function index(Request $request): JsonResponse
    {
        $challenges = Challenge::with('category')
            ->when($request->type, fn($q) => $q->where('type', $request->type))
            ->when($request->is_active !== null, fn($q) => $q->where('is_active', (bool) $request->is_active))
            ->when($request->is_pro !== null, fn($q) => $q->where('is_pro', (bool) $request->is_pro))
            ->when($request->category_id, fn($q) => $q->where('category_id', $request->category_id))
            ->when($request->search, fn($q) => $q->where('title', 'like', "%{$request->search}%"))
            ->orderBy('sort_order')
            ->orderByDesc('completion_count')
            ->paginate($request->per_page ?? 25);

        return response()->json(['success' => true, 'data' => $challenges]);
    }

    /**
     * POST /admin/challenges
     */
    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'category_id'       => 'required|exists:challenge_categories,id',
            'slug'              => 'required|string|unique:challenges,slug',
            'title'             => 'required|string|max:255',
            'description'       => 'required|string',
            'type'              => 'required|in:learning_task,reflection,mini_challenge,focus_timer,habit_task,delay_timer',
            'content'           => 'nullable|string',
            'difficulty'        => 'required|in:easy,medium,hard',
            'reward_minutes'    => 'required|integer|min:1|max:60',
            'estimated_seconds' => 'required|integer|min:10',
            'is_pro'            => 'boolean',
            'is_active'         => 'boolean',
            'goal'              => 'nullable|string|max:100',
            'cooldown_minutes'  => 'integer|min:0',
            'sort_order'        => 'integer|min:0',
        ]);

        $challenge = Challenge::create($validated);

        return response()->json([
            'success' => true,
            'data'    => $challenge->load('category'),
        ], 201);
    }

    /**
     * GET /admin/challenges/{challenge}
     */
    public function show(Challenge $challenge): JsonResponse
    {
        $challenge->load('category');

        $stats = [
            'completion_rate' => $challenge->completion_count + $challenge->skip_count > 0
                ? round($challenge->completion_count / ($challenge->completion_count + $challenge->skip_count) * 100, 1)
                : null,
            'skip_rate' => $challenge->completion_count + $challenge->skip_count > 0
                ? round($challenge->skip_count / ($challenge->completion_count + $challenge->skip_count) * 100, 1)
                : null,
            'total_attempts' => $challenge->completion_count + $challenge->skip_count,
        ];

        return response()->json([
            'success' => true,
            'data'    => array_merge($challenge->toArray(), ['stats' => $stats]),
        ]);
    }

    /**
     * PUT /admin/challenges/{challenge}
     */
    public function update(Request $request, Challenge $challenge): JsonResponse
    {
        $validated = $request->validate([
            'category_id'        => 'sometimes|exists:challenge_categories,id',
            'slug'               => "sometimes|string|unique:challenges,slug,{$challenge->id}",
            'title'              => 'sometimes|string|max:255',
            'description'        => 'sometimes|string',
            'type'               => 'sometimes|in:learning_task,reflection,mini_challenge,focus_timer,habit_task,delay_timer',
            'content'            => 'nullable|string',
            'difficulty'         => 'sometimes|in:easy,medium,hard',
            'reward_minutes'     => 'sometimes|integer|min:1|max:60',
            'estimated_seconds'  => 'sometimes|integer|min:10',
            'is_pro'             => 'boolean',
            'is_active'          => 'boolean',
            'goal'               => 'nullable|string|max:100',
            'cooldown_minutes'   => 'integer|min:0',
            'effectiveness_score'=> 'nullable|numeric|min:0|max:5',
            'sort_order'         => 'integer|min:0',
        ]);

        $challenge->update($validated);

        return response()->json([
            'success' => true,
            'data'    => $challenge->fresh(['category']),
        ]);
    }

    /**
     * DELETE /admin/challenges/{challenge}
     */
    public function destroy(Challenge $challenge): JsonResponse
    {
        // Soft-disable rather than hard delete to preserve completion history
        $challenge->update(['is_active' => false]);

        return response()->json([
            'success' => true,
            'message' => "Challenge '{$challenge->title}' deactivated.",
        ]);
    }
}
