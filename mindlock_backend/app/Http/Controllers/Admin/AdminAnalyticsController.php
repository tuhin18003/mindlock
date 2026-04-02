<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Services\AnalyticsAggregationService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;

class AdminAnalyticsController extends Controller
{
    public function __construct(
        private readonly AnalyticsAggregationService $analyticsService,
    ) {}

    /**
     * GET /admin/analytics/overview
     * Product-level overview stats.
     */
    public function overview(Request $request): JsonResponse
    {
        $from = Carbon::parse($request->from ?? now()->subDays(30));
        $to   = Carbon::parse($request->to ?? now());

        $overview = $this->analyticsService->getProductOverview($from, $to);

        // DAU trend
        $dauTrend = DB::table('device_sessions')
            ->select(DB::raw('DATE(last_seen_at) as date'), DB::raw('COUNT(DISTINCT user_id) as dau'))
            ->whereBetween('last_seen_at', [$from, $to])
            ->groupBy('date')
            ->orderBy('date')
            ->get();

        // New users trend
        $registrationTrend = DB::table('users')
            ->select(DB::raw('DATE(created_at) as date'), DB::raw('COUNT(*) as count'))
            ->whereBetween('created_at', [$from, $to])
            ->groupBy('date')
            ->orderBy('date')
            ->get();

        $entitlementBreakdown = DB::table('entitlements')
            ->where('status', 'active')
            ->select('source', DB::raw('COUNT(*) as count'))
            ->groupBy('source')
            ->get();

        return response()->json([
            'success' => true,
            'data' => [
                'summary'               => $overview,
                'dau_trend'             => $dauTrend,
                'registration_trend'    => $registrationTrend,
                'entitlement_breakdown' => $entitlementBreakdown,
            ],
        ]);
    }

    /**
     * GET /admin/analytics/usage
     * App usage patterns.
     */
    public function usageAnalytics(Request $request): JsonResponse
    {
        $from = Carbon::parse($request->from ?? now()->subDays(30));
        $to   = Carbon::parse($request->to ?? now());

        $topApps = DB::table('usage_logs')
            ->select('package_name', DB::raw('SUM(usage_seconds) as total_seconds'), DB::raw('COUNT(DISTINCT user_id) as user_count'))
            ->whereBetween('date', [$from->toDateString(), $to->toDateString()])
            ->groupBy('package_name')
            ->orderByDesc('total_seconds')
            ->limit(20)
            ->get();

        $categoryBreakdown = DB::table('usage_logs')
            ->select('category', DB::raw('SUM(usage_seconds) as total_seconds'))
            ->whereNotNull('category')
            ->whereBetween('date', [$from->toDateString(), $to->toDateString()])
            ->groupBy('category')
            ->orderByDesc('total_seconds')
            ->get();

        $avgScreenTime = DB::table('analytics_daily_summaries')
            ->whereBetween('date', [$from->toDateString(), $to->toDateString()])
            ->avg('total_screen_time_seconds');

        return response()->json([
            'success' => true,
            'data' => [
                'top_apps'           => $topApps,
                'category_breakdown' => $categoryBreakdown,
                'avg_screen_seconds' => (int) $avgScreenTime,
            ],
        ]);
    }

    /**
     * GET /admin/analytics/unlock
     * Unlock behavior patterns.
     */
    public function unlockAnalytics(Request $request): JsonResponse
    {
        $from = Carbon::parse($request->from ?? now()->subDays(30));
        $to   = Carbon::parse($request->to ?? now());

        $methodBreakdown = DB::table('unlock_events')
            ->select('method', DB::raw('COUNT(*) as count'))
            ->whereBetween('unlocked_at', [$from, $to])
            ->groupBy('method')
            ->orderByDesc('count')
            ->get();

        $totalLocks   = DB::table('lock_events')->whereBetween('locked_at', [$from, $to])->count();
        $totalUnlocks = DB::table('unlock_events')->whereBetween('unlocked_at', [$from, $to])->count();
        $emergencyTotal = DB::table('emergency_unlocks')->whereBetween('used_at', [$from, $to])->count();
        $relockTotal  = DB::table('unlock_events')->whereBetween('unlocked_at', [$from, $to])->where('relocked', true)->count();

        return response()->json([
            'success' => true,
            'data' => [
                'total_lock_events'    => $totalLocks,
                'total_unlock_events'  => $totalUnlocks,
                'emergency_unlocks'    => $emergencyTotal,
                'relock_events'        => $relockTotal,
                'unlock_success_rate'  => $totalLocks > 0 ? round($totalUnlocks / $totalLocks * 100, 2) : 0,
                'emergency_rate'       => $totalUnlocks > 0 ? round($emergencyTotal / $totalUnlocks * 100, 2) : 0,
                'relock_rate'          => $totalUnlocks > 0 ? round($relockTotal / $totalUnlocks * 100, 2) : 0,
                'method_breakdown'     => $methodBreakdown,
            ],
        ]);
    }

    /**
     * GET /admin/analytics/challenges
     * Challenge effectiveness.
     */
    public function challengeAnalytics(Request $request): JsonResponse
    {
        $from = Carbon::parse($request->from ?? now()->subDays(30));
        $to   = Carbon::parse($request->to ?? now());

        $byType = DB::table('challenge_completions as cc')
            ->join('challenges as c', 'c.id', '=', 'cc.challenge_id')
            ->select(
                'c.type',
                DB::raw('COUNT(*) as total'),
                DB::raw("SUM(CASE WHEN cc.result = 'completed' THEN 1 ELSE 0 END) as completed"),
                DB::raw("SUM(CASE WHEN cc.result = 'skipped' THEN 1 ELSE 0 END) as skipped"),
                DB::raw("SUM(CASE WHEN cc.result = 'failed' THEN 1 ELSE 0 END) as failed"),
                DB::raw('AVG(cc.time_seconds) as avg_time_seconds'),
            )
            ->whereBetween('cc.completed_at', [$from, $to])
            ->groupBy('c.type')
            ->get();

        return response()->json(['success' => true, 'data' => $byType]);
    }

    /**
     * GET /admin/analytics/entitlements
     * Entitlement source breakdown and Pro adoption trend.
     */
    public function entitlementAnalytics(Request $request): JsonResponse
    {
        $from = Carbon::parse($request->from ?? now()->subDays(30));
        $to   = Carbon::parse($request->to ?? now());

        $bySource = DB::table('entitlements')
            ->select('source', DB::raw('COUNT(*) as count'))
            ->groupBy('source')
            ->orderByDesc('count')
            ->get();

        $byStatus = DB::table('entitlements')
            ->where('tier', 'pro')
            ->select('status', DB::raw('COUNT(*) as count'))
            ->groupBy('status')
            ->get();

        $grantsTrend = DB::table('entitlements')
            ->where('tier', 'pro')
            ->whereBetween('created_at', [$from, $to])
            ->select(DB::raw('DATE(created_at) as date'), DB::raw('COUNT(*) as count'))
            ->groupBy('date')
            ->orderBy('date')
            ->get();

        $totalPro  = DB::table('entitlements')->where('tier', 'pro')->where('status', 'active')->count();
        $totalFree = DB::table('users')->where('status', 'active')->count() - $totalPro;

        return response()->json([
            'success' => true,
            'data'    => [
                'total_pro_active'   => $totalPro,
                'total_free'         => max(0, $totalFree),
                'pro_adoption_rate'  => ($totalPro + $totalFree) > 0
                    ? round($totalPro / ($totalPro + $totalFree) * 100, 2)
                    : 0,
                'by_source'          => $bySource,
                'by_status'          => $byStatus,
                'grants_trend'       => $grantsTrend,
            ],
        ]);
    }

    /**
     * GET /admin/analytics/risk
     * Risk signals — suspicious unlock patterns, heavy emergency users.
     */
    public function riskAnalytics(Request $request): JsonResponse
    {
        $from = Carbon::parse($request->from ?? now()->subDays(30));
        $to   = Carbon::parse($request->to ?? now());

        // Users with high emergency unlock rates
        $heavyEmergencyUsers = DB::table('emergency_unlocks')
            ->select('user_id', DB::raw('COUNT(*) as count'))
            ->whereBetween('used_at', [$from, $to])
            ->groupBy('user_id')
            ->having('count', '>=', 5)
            ->orderByDesc('count')
            ->limit(20)
            ->get();

        // Users with high relock rates (keep relocking within 10 minutes)
        $relockHeavyUsers = DB::table('unlock_events')
            ->select('user_id', DB::raw('COUNT(*) as count'))
            ->where('relocked', true)
            ->whereBetween('unlocked_at', [$from, $to])
            ->groupBy('user_id')
            ->having('count', '>=', 5)
            ->orderByDesc('count')
            ->limit(20)
            ->get();

        return response()->json([
            'success' => true,
            'data'    => [
                'heavy_emergency_users' => $heavyEmergencyUsers,
                'heavy_relock_users'    => $relockHeavyUsers,
            ],
        ]);
    }
}
