<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\ChallengeCategory;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ChallengeCategoryController extends Controller
{
    /**
     * GET /admin/challenge-categories
     */
    public function index(): JsonResponse
    {
        $categories = ChallengeCategory::withCount(['challenges', 'challenges as active_challenges_count' => fn($q) => $q->where('is_active', true)])
            ->orderBy('sort_order')
            ->get();

        return response()->json(['success' => true, 'data' => $categories]);
    }

    /**
     * POST /admin/challenge-categories
     */
    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'slug'        => 'required|string|unique:challenge_categories,slug',
            'name'        => 'required|string|max:100',
            'description' => 'nullable|string',
            'icon'        => 'nullable|string|max:100',
            'color'       => 'nullable|string|max:20',
            'is_active'   => 'boolean',
            'sort_order'  => 'integer|min:0',
        ]);

        $category = ChallengeCategory::create($validated);

        return response()->json(['success' => true, 'data' => $category], 201);
    }

    /**
     * GET /admin/challenge-categories/{category}
     */
    public function show(ChallengeCategory $challengeCategory): JsonResponse
    {
        $challengeCategory->load('challenges');

        return response()->json(['success' => true, 'data' => $challengeCategory]);
    }

    /**
     * PUT /admin/challenge-categories/{category}
     */
    public function update(Request $request, ChallengeCategory $challengeCategory): JsonResponse
    {
        $validated = $request->validate([
            'slug'        => "sometimes|string|unique:challenge_categories,slug,{$challengeCategory->id}",
            'name'        => 'sometimes|string|max:100',
            'description' => 'nullable|string',
            'icon'        => 'nullable|string|max:100',
            'color'       => 'nullable|string|max:20',
            'is_active'   => 'boolean',
            'sort_order'  => 'integer|min:0',
        ]);

        $challengeCategory->update($validated);

        return response()->json(['success' => true, 'data' => $challengeCategory->fresh()]);
    }

    /**
     * DELETE /admin/challenge-categories/{category}
     */
    public function destroy(ChallengeCategory $challengeCategory): JsonResponse
    {
        // Prevent deletion if it has active challenges
        if ($challengeCategory->challenges()->where('is_active', true)->exists()) {
            return response()->json([
                'success' => false,
                'message' => 'Cannot delete a category that has active challenges. Deactivate challenges first.',
            ], 422);
        }

        $challengeCategory->update(['is_active' => false]);

        return response()->json([
            'success' => true,
            'message' => "Category '{$challengeCategory->name}' deactivated.",
        ]);
    }
}
