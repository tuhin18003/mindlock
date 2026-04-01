<?php

namespace App\Services;

use App\Models\AnalyticsDailySummary;
use App\Models\AnalyticsEvent;
use App\Models\User;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;

class AnalyticsAggregationService
{
    /**
     * Ingest analytics events in batch.
     */
    public function ingestBatch(User $user, string $deviceId, string $platform, string $appVersion, array $events): void
    {
        $records = [];
        foreach ($events as $event) {
            $records[] = [
                'event_name'       => $event['event'],
                'user_id'          => $user->id,
                'session_id'       => $event['session_id'] ?? null,
                'device_id'        => $deviceId,
                'platform'         => $platform,
                'app_version'      => $appVersion,
                'timezone'         => $event['timezone'] ?? $user->timezone,
                'entitlement_tier' => $event['entitlement_tier'] ?? null,
                'properties'       => json_encode($event['properties'] ?? []),
                'occurred_at'      => Carbon::parse($event['timestamp'] ?? now()),
                'created_at'       => now(),
                'updated_at'       => now(),
            ];
        }

        // Chunked insert to avoid query size limits
        foreach (array_chunk($records, 100) as $chunk) {
            DB::table('analytics_events')->insert($chunk);
        }
    }

    /**
     * Aggregate daily summary for a user/date (run via job/scheduler).
     */
    public function aggregateDailySummary(User $user, Carbon $date): AnalyticsDailySummary
    {
        $dateStr = $date->toDateString();

        $screenSeconds    = DB::table('usage_logs')
            ->where('user_id', $user->id)->where('date', $dateStr)
            ->sum('usage_seconds');

        $recoveredMinutes = DB::table('unlock_events')
            ->where('user_id', $user->id)->whereDate('unlocked_at', $dateStr)
            ->sum('reward_minutes');

        $lockTriggers = DB::table('lock_events')
            ->where('user_id', $user->id)->whereDate('locked_at', $dateStr)
            ->count();

        $unlockAttempts = DB::table('unlock_events')
            ->where('user_id', $user->id)->whereDate('unlocked_at', $dateStr)
            ->count();

        $challengeCompletions = DB::table('challenge_completions')
            ->where('user_id', $user->id)->where('result', 'completed')
            ->whereDate('completed_at', $dateStr)->count();

        $emergencyUnlocks = DB::table('emergency_unlocks')
            ->where('user_id', $user->id)->whereDate('used_at', $dateStr)
            ->count();

        $relockEvents = DB::table('unlock_events')
            ->where('user_id', $user->id)->where('relocked', true)
            ->whereDate('unlocked_at', $dateStr)->count();

        $focusSeconds = DB::table('focus_sessions')
            ->where('user_id', $user->id)->where('status', 'completed')
            ->whereDate('started_at', $dateStr)
            ->sum(DB::raw('actual_minutes * 60'));

        $streak = $user->streak;
        $streakMaintained = $streak?->last_streak_date === $dateStr;

        return AnalyticsDailySummary::updateOrCreate(
            ['user_id' => $user->id, 'date' => $dateStr],
            [
                'total_screen_time_seconds' => $screenSeconds,
                'recovered_time_seconds'    => $recoveredMinutes * 60,
                'lock_triggers'             => $lockTriggers,
                'unlock_attempts'           => $unlockAttempts,
                'challenge_completions'     => $challengeCompletions,
                'emergency_unlocks'         => $emergencyUnlocks,
                'relock_events'             => $relockEvents,
                'focus_time_seconds'        => $focusSeconds,
                'streak_maintained'         => $streakMaintained,
            ]
        );
    }

    /**
     * Get admin-level product overview stats.
     */
    public function getProductOverview(Carbon $from, Carbon $to): array
    {
        return [
            'total_users'       => DB::table('users')->where('status', 'active')->count(),
            'pro_users'         => DB::table('entitlements')
                ->where('tier', 'pro')->where('status', 'active')
                ->distinct('user_id')->count('user_id'),
            'dau'               => DB::table('device_sessions')
                ->whereDate('last_seen_at', today())->distinct('user_id')->count('user_id'),
            'new_registrations' => DB::table('users')
                ->whereBetween('created_at', [$from, $to])->count(),
            'total_lock_events' => DB::table('lock_events')
                ->whereBetween('locked_at', [$from, $to])->count(),
            'total_recovered_minutes' => DB::table('unlock_events')
                ->whereBetween('unlocked_at', [$from, $to])->sum('reward_minutes'),
            'emergency_unlock_total'  => DB::table('emergency_unlocks')
                ->whereBetween('used_at', [$from, $to])->count(),
            'challenge_completions'   => DB::table('challenge_completions')
                ->where('result', 'completed')
                ->whereBetween('completed_at', [$from, $to])->count(),
        ];
    }
}
