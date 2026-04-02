<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\AnalyticsDailySummary;
use App\Models\RecoveryScore;
use App\Services\RecoveryScoreService;
use App\Services\UsageSyncService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;

class DashboardController extends Controller
{
    public function __construct(
        private readonly RecoveryScoreService $recoveryScoreService,
        private readonly UsageSyncService $syncService,
    ) {}

    /**
     * GET /api/v1/dashboard/today
     */
    public function today(Request $request): JsonResponse
    {
        $user  = $request->user();
        $today = now()->toDateString();

        $summary = $user->dailySummaries()->where('date', $today)->first();
        $streak  = $user->streak;
        $score   = $user->recoveryScores()->where('date', $today)->first();

        $topApps = DB::table('usage_logs')
            ->where('user_id', $user->id)
            ->where('date', $today)
            ->orderByDesc('usage_seconds')
            ->limit(5)
            ->get(['package_name', 'usage_seconds', 'category']);

        return response()->json([
            'success' => true,
            'data'    => [
                'date'                   => $today,
                'screen_time_seconds'    => $summary?->total_screen_time_seconds ?? 0,
                'recovered_time_seconds' => $summary?->recovered_time_seconds ?? 0,
                'focus_time_seconds'     => $summary?->focus_time_seconds ?? 0,
                'lock_triggers'          => $summary?->lock_triggers ?? 0,
                'challenge_completions'  => $summary?->challenge_completions ?? 0,
                'emergency_unlocks'      => $summary?->emergency_unlocks ?? 0,
                'streak'                 => [
                    'current'    => $streak?->current_streak ?? 0,
                    'longest'    => $streak?->longest_streak ?? 0,
                    'maintained' => $summary?->streak_maintained ?? false,
                ],
                'recovery_score'         => $score?->score ?? 0,
                'top_apps'               => $topApps,
            ],
        ]);
    }

    /**
     * GET /api/v1/dashboard/weekly
     */
    public function weekly(Request $request): JsonResponse
    {
        $user     = $request->user();
        $fromDate = now()->subDays(6)->toDateString();
        $toDate   = now()->toDateString();

        $dailySummaries = $user->dailySummaries()
            ->whereBetween('date', [$fromDate, $toDate])
            ->orderBy('date')
            ->get();

        $recoveryScores = $user->recoveryScores()
            ->whereBetween('date', [$fromDate, $toDate])
            ->orderBy('date')
            ->get(['date', 'score'])
            ->keyBy('date');

        // Top apps for the week
        $topApps = DB::table('usage_logs')
            ->where('user_id', $user->id)
            ->whereBetween('date', [$fromDate, $toDate])
            ->select('package_name', 'category', DB::raw('SUM(usage_seconds) as total_seconds'))
            ->groupBy('package_name', 'category')
            ->orderByDesc('total_seconds')
            ->limit(10)
            ->get();

        $totals = [
            'screen_time_seconds'    => $dailySummaries->sum('total_screen_time_seconds'),
            'recovered_time_seconds' => $dailySummaries->sum('recovered_time_seconds'),
            'focus_time_seconds'     => $dailySummaries->sum('focus_time_seconds'),
            'lock_triggers'          => $dailySummaries->sum('lock_triggers'),
            'challenge_completions'  => $dailySummaries->sum('challenge_completions'),
            'emergency_unlocks'      => $dailySummaries->sum('emergency_unlocks'),
            'avg_recovery_score'     => $recoveryScores->avg('score') ? round($recoveryScores->avg('score')) : 0,
        ];

        $trend = $dailySummaries->map(fn($d) => [
            'date'                => $d->date,
            'screen_seconds'      => $d->total_screen_time_seconds,
            'recovered_seconds'   => $d->recovered_time_seconds,
            'challenge_completions' => $d->challenge_completions,
            'recovery_score'      => $recoveryScores->get($d->date)?->score ?? 0,
        ]);

        return response()->json([
            'success' => true,
            'data'    => [
                'from'      => $fromDate,
                'to'        => $toDate,
                'totals'    => $totals,
                'trend'     => $trend,
                'top_apps'  => $topApps,
            ],
        ]);
    }

    /**
     * GET /api/v1/dashboard/monthly
     */
    public function monthly(Request $request): JsonResponse
    {
        $user     = $request->user();
        $fromDate = now()->startOfMonth()->toDateString();
        $toDate   = now()->toDateString();

        $summaries = $user->dailySummaries()
            ->whereBetween('date', [$fromDate, $toDate])
            ->get();

        // Aggregate by week
        $weeklyBreakdown = $summaries->groupBy(fn($d) => Carbon::parse($d->date)->startOfWeek()->toDateString())
            ->map(fn($week) => [
                'week_start'             => $week->first()->date,
                'screen_time_seconds'    => $week->sum('total_screen_time_seconds'),
                'recovered_seconds'      => $week->sum('recovered_time_seconds'),
                'challenge_completions'  => $week->sum('challenge_completions'),
                'emergency_unlocks'      => $week->sum('emergency_unlocks'),
            ])
            ->values();

        $topApps = DB::table('usage_logs')
            ->where('user_id', $user->id)
            ->whereBetween('date', [$fromDate, $toDate])
            ->select('package_name', 'category', DB::raw('SUM(usage_seconds) as total_seconds'))
            ->groupBy('package_name', 'category')
            ->orderByDesc('total_seconds')
            ->limit(10)
            ->get();

        return response()->json([
            'success' => true,
            'data'    => [
                'from'             => $fromDate,
                'to'               => $toDate,
                'total_screen_seconds' => $summaries->sum('total_screen_time_seconds'),
                'total_recovered_seconds' => $summaries->sum('recovered_time_seconds'),
                'total_challenges' => $summaries->sum('challenge_completions'),
                'total_locks'      => $summaries->sum('lock_triggers'),
                'weekly_breakdown' => $weeklyBreakdown,
                'top_apps'         => $topApps,
                'days_active'      => $summaries->where('total_screen_time_seconds', '>', 0)->count(),
            ],
        ]);
    }

    /**
     * GET /api/v1/dashboard/score
     */
    public function recoveryScore(Request $request): JsonResponse
    {
        $user  = $request->user();
        $today = now()->toDateString();

        // Recompute today's score fresh
        $score = $this->recoveryScoreService->computeForDate($user, now());

        // Trend for last 30 days
        $trend = $this->recoveryScoreService->getScoreTrend($user, 30);

        $avgScore = collect($trend)->avg('score');

        return response()->json([
            'success' => true,
            'data'    => [
                'today'     => $score->score,
                'avg_30d'   => $avgScore ? round($avgScore) : 0,
                'trend'     => $trend,
                'breakdown' => [
                    'recovered_minutes'     => $score->recovered_minutes,
                    'challenge_completions' => $score->challenge_completions,
                    'emergency_unlocks'     => $score->emergency_unlocks,
                    'relock_count'          => $score->relock_count,
                ],
            ],
        ]);
    }
}
