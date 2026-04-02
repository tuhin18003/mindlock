<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Services\EntitlementResolver;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class HistoryController extends Controller
{
    public function __construct(
        private readonly EntitlementResolver $entitlementResolver,
    ) {}

    /**
     * GET /api/v1/history/activity
     * Unified activity timeline — lock, unlock, challenge, focus events.
     */
    public function activity(Request $request): JsonResponse
    {
        $user   = $request->user();
        $limit  = min((int) ($request->limit ?? 30), 100);
        $before = $request->before ? now()->parse($request->before) : now();

        // Union approach — collect events from multiple tables
        $lockEvents = DB::table('lock_events')
            ->where('user_id', $user->id)
            ->where('locked_at', '<', $before)
            ->select(
                DB::raw("'lock' as event_type"),
                'local_event_id as event_id',
                'package_name',
                'app_name',
                DB::raw('NULL as method'),
                DB::raw('NULL as reward_minutes'),
                DB::raw('NULL as result'),
                'locked_at as occurred_at'
            );

        $unlockEvents = DB::table('unlock_events')
            ->where('user_id', $user->id)
            ->where('unlocked_at', '<', $before)
            ->select(
                DB::raw("'unlock' as event_type"),
                'local_event_id as event_id',
                'package_name',
                DB::raw('NULL as app_name'),
                'method',
                'reward_minutes',
                DB::raw('NULL as result'),
                'unlocked_at as occurred_at'
            );

        $challengeEvents = DB::table('challenge_completions as cc')
            ->join('challenges as c', 'c.id', '=', 'cc.challenge_id')
            ->where('cc.user_id', $user->id)
            ->where('cc.completed_at', '<', $before)
            ->select(
                DB::raw("'challenge' as event_type"),
                'cc.local_event_id as event_id',
                'cc.package_name',
                DB::raw('NULL as app_name'),
                'c.type as method',
                'cc.reward_granted_minutes as reward_minutes',
                'cc.result',
                'cc.completed_at as occurred_at'
            );

        $focusEvents = DB::table('focus_sessions')
            ->where('user_id', $user->id)
            ->where('status', 'completed')
            ->where('started_at', '<', $before)
            ->select(
                DB::raw("'focus' as event_type"),
                'local_event_id as event_id',
                DB::raw('NULL as package_name'),
                DB::raw('NULL as app_name'),
                DB::raw('NULL as method'),
                DB::raw('actual_minutes as reward_minutes'),
                DB::raw("'completed' as result"),
                'started_at as occurred_at'
            );

        $emergencies = DB::table('emergency_unlocks')
            ->where('user_id', $user->id)
            ->where('used_at', '<', $before)
            ->select(
                DB::raw("'emergency' as event_type"),
                'local_event_id as event_id',
                'package_name',
                DB::raw('NULL as app_name'),
                DB::raw("'emergency' as method"),
                DB::raw('NULL as reward_minutes'),
                DB::raw('NULL as result'),
                'used_at as occurred_at'
            );

        $combined = $lockEvents
            ->union($unlockEvents)
            ->union($challengeEvents)
            ->union($focusEvents)
            ->union($emergencies);

        $results = DB::table(DB::raw("({$combined->toSql()}) as activity"))
            ->mergeBindings($lockEvents)
            ->mergeBindings($unlockEvents)
            ->mergeBindings($challengeEvents)
            ->mergeBindings($focusEvents)
            ->mergeBindings($emergencies)
            ->orderByDesc('occurred_at')
            ->limit($limit)
            ->get();

        return response()->json([
            'success'   => true,
            'data'      => $results,
            'has_more'  => $results->count() === $limit,
            'next_before' => $results->last()?->occurred_at,
        ]);
    }

    /**
     * GET /api/v1/history/locks
     */
    public function locks(Request $request): JsonResponse
    {
        $user  = $request->user();
        $query = $user->lockEvents()
            ->when($request->package, fn($q) => $q->where('package_name', $request->package))
            ->when($request->from, fn($q) => $q->where('locked_at', '>=', $request->from))
            ->when($request->to, fn($q) => $q->where('locked_at', '<=', $request->to))
            ->orderByDesc('locked_at')
            ->paginate($request->per_page ?? 20);

        return response()->json(['success' => true, 'data' => $query]);
    }

    /**
     * GET /api/v1/history/challenges
     */
    public function challenges(Request $request): JsonResponse
    {
        $user  = $request->user();
        $query = $user->challengeCompletions()
            ->with('challenge:id,title,type,difficulty,reward_minutes')
            ->when($request->result, fn($q) => $q->where('result', $request->result))
            ->when($request->from, fn($q) => $q->where('completed_at', '>=', $request->from))
            ->when($request->to, fn($q) => $q->where('completed_at', '<=', $request->to))
            ->orderByDesc('completed_at')
            ->paginate($request->per_page ?? 20);

        return response()->json(['success' => true, 'data' => $query]);
    }

    /**
     * GET /api/v1/history/focus
     */
    public function focus(Request $request): JsonResponse
    {
        $user  = $request->user();
        $query = $user->focusSessions()
            ->when($request->status, fn($q) => $q->where('status', $request->status))
            ->when($request->from, fn($q) => $q->where('started_at', '>=', $request->from))
            ->orderByDesc('started_at')
            ->paginate($request->per_page ?? 20);

        return response()->json(['success' => true, 'data' => $query]);
    }

    /**
     * GET /api/v1/history/emergency-unlocks
     */
    public function emergencyUnlocks(Request $request): JsonResponse
    {
        $user  = $request->user();
        $query = $user->emergencyUnlocks()
            ->when($request->from, fn($q) => $q->where('used_at', '>=', $request->from))
            ->orderByDesc('used_at')
            ->paginate($request->per_page ?? 20);

        return response()->json(['success' => true, 'data' => $query]);
    }

    /**
     * GET /api/v1/history/stats
     * Aggregate stats for the history page header.
     */
    public function stats(Request $request): JsonResponse
    {
        $user = $request->user();
        $days = (int) ($request->days ?? 30);
        $from = now()->subDays($days);

        return response()->json([
            'success' => true,
            'data'    => [
                'period_days'           => $days,
                'total_locks'           => $user->lockEvents()->where('locked_at', '>=', $from)->count(),
                'total_challenges'      => $user->challengeCompletions()->where('result', 'completed')->where('completed_at', '>=', $from)->count(),
                'total_emergency_unlocks' => $user->emergencyUnlocks()->where('used_at', '>=', $from)->count(),
                'total_recovered_minutes' => $user->unlockEvents()->where('unlocked_at', '>=', $from)->sum('reward_minutes'),
                'total_focus_minutes'   => $user->focusSessions()->where('status', 'completed')->where('started_at', '>=', $from)->sum('actual_minutes'),
                'challenge_success_rate' => $this->challengeSuccessRate($user, $from),
                'most_locked_app'       => $user->lockEvents()->where('locked_at', '>=', $from)->select('package_name')->groupBy('package_name')->orderByRaw('COUNT(*) DESC')->value('package_name'),
            ],
        ]);
    }

    private function challengeSuccessRate($user, $from): float
    {
        $total     = $user->challengeCompletions()->where('completed_at', '>=', $from)->count();
        $completed = $user->challengeCompletions()->where('result', 'completed')->where('completed_at', '>=', $from)->count();
        return $total > 0 ? round($completed / $total * 100, 1) : 0;
    }
}
