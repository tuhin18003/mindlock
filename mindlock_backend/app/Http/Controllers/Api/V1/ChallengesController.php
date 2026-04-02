<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Challenge;
use App\Models\ChallengeCategory;
use App\Services\EntitlementResolver;
use App\Services\FeatureGateService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;

class ChallengesController extends Controller
{
    public function __construct(
        private readonly EntitlementResolver $entitlementResolver,
        private readonly FeatureGateService  $featureGateService,
    ) {}

    /**
     * GET /api/v1/challenges
     * Returns the challenge library for the current user (filtered by Pro access).
     */
    public function index(Request $request): JsonResponse
    {
        $user  = $request->user();
        $isPro = $this->entitlementResolver->isPro($user);

        $challenges = Challenge::with('category')
            ->where('is_active', true)
            ->when(!$isPro, fn($q) => $q->where('is_pro', false))
            ->when($request->type, fn($q) => $q->where('type', $request->type))
            ->when($request->category, fn($q) => $q->whereHas('category', fn($c) => $c->where('slug', $request->category)))
            ->orderBy('sort_order')
            ->orderByDesc('completion_count')
            ->get();

        return response()->json([
            'success' => true,
            'data'    => $challenges->map(fn($c) => $this->formatChallenge($c)),
        ]);
    }

    /**
     * GET /api/v1/challenges/categories
     * Returns all active categories with their available challenges count.
     */
    public function categories(Request $request): JsonResponse
    {
        $user  = $request->user();
        $isPro = $this->entitlementResolver->isPro($user);

        $categories = ChallengeCategory::withCount([
            'challenges as available_count' => fn($q) => $q
                ->where('is_active', true)
                ->when(!$isPro, fn($cq) => $cq->where('is_pro', false)),
        ])
            ->where('is_active', true)
            ->orderBy('sort_order')
            ->get();

        return response()->json(['success' => true, 'data' => $categories]);
    }

    /**
     * GET /api/v1/challenges/{challenge}
     * Returns a specific challenge — gated for Pro-only challenges.
     */
    public function show(Request $request, Challenge $challenge): JsonResponse
    {
        if (!$challenge->is_active) {
            return response()->json(['success' => false, 'message' => 'Challenge not available.'], 404);
        }

        $user  = $request->user();
        $isPro = $this->entitlementResolver->isPro($user);

        if ($challenge->is_pro && !$isPro) {
            return response()->json([
                'success'        => false,
                'message'        => 'This challenge requires Pro access.',
                'upgrade_required' => true,
            ], 403);
        }

        return response()->json([
            'success' => true,
            'data'    => $this->formatChallenge($challenge->load('category')),
        ]);
    }

    /**
     * GET /api/v1/challenges/for-intervention
     * Returns a curated set of 3-5 challenges suitable for an unlock intervention.
     * Considers: user's preferred types, cooldowns, free vs pro.
     */
    public function forIntervention(Request $request): JsonResponse
    {
        $user    = $request->user();
        $isPro   = $this->entitlementResolver->isPro($user);

        // Get recently completed challenge IDs (last 24h) to avoid repeats
        $recentIds = $user->challengeCompletions()
            ->where('result', 'completed')
            ->where('completed_at', '>=', now()->subHours(24))
            ->pluck('challenge_id')
            ->toArray();

        // Preferred types based on past completions
        $preferredType = $user->challengeCompletions()
            ->join('challenges', 'challenges.id', '=', 'challenge_completions.challenge_id')
            ->where('challenge_completions.result', 'completed')
            ->select('challenges.type')
            ->groupBy('challenges.type')
            ->orderByRaw('COUNT(*) DESC')
            ->value('challenges.type');

        $query = Challenge::with('category')
            ->where('is_active', true)
            ->when(!$isPro, fn($q) => $q->where('is_pro', false))
            ->whereNotIn('id', $recentIds);

        // Always include at least 1 reflection (free)
        $reflection = (clone $query)
            ->where('type', 'reflection')
            ->where('difficulty', 'easy')
            ->inRandomOrder()
            ->first();

        // Include a learning task
        $learning = (clone $query)
            ->where('type', 'learning_task')
            ->inRandomOrder()
            ->first();

        // Include user's preferred type if different
        $preferred = null;
        if ($preferredType && !in_array($preferredType, ['reflection', 'learning_task'])) {
            $preferred = (clone $query)
                ->where('type', $preferredType)
                ->inRandomOrder()
                ->first();
        }

        // Fill remaining slots
        $remaining = (clone $query)
            ->whereNotIn('id', array_filter([
                $reflection?->id,
                $learning?->id,
                $preferred?->id,
            ]))
            ->inRandomOrder()
            ->limit(2)
            ->get();

        $challenges = collect(array_filter([$reflection, $learning, $preferred]))
            ->merge($remaining)
            ->unique('id')
            ->take(5)
            ->values();

        return response()->json([
            'success' => true,
            'data'    => $challenges->map(fn($c) => $this->formatChallenge($c)),
        ]);
    }

    private function formatChallenge(Challenge $challenge): array
    {
        return [
            'id'               => $challenge->id,
            'slug'             => $challenge->slug,
            'title'            => $challenge->title,
            'description'      => $challenge->description,
            'type'             => $challenge->type,
            'content'          => $challenge->content,
            'difficulty'       => $challenge->difficulty,
            'reward_minutes'   => $challenge->reward_minutes,
            'estimated_seconds'=> $challenge->estimated_seconds,
            'is_pro'           => $challenge->is_pro,
            'goal'             => $challenge->goal,
            'cooldown_minutes' => $challenge->cooldown_minutes,
            'category'         => $challenge->category ? [
                'id'    => $challenge->category->id,
                'slug'  => $challenge->category->slug,
                'name'  => $challenge->category->name,
                'icon'  => $challenge->category->icon,
                'color' => $challenge->category->color,
            ] : null,
        ];
    }
}
