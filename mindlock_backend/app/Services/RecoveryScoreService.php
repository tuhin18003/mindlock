<?php

namespace App\Services;

use App\Models\RecoveryScore;
use App\Models\User;
use Illuminate\Support\Carbon;

/**
 * RecoveryScoreService — computes daily recovery score (0-100).
 *
 * Score factors:
 * - Recovered time vs screen time (30 pts)
 * - Challenge completions (20 pts)
 * - Emergency unlock discipline (20 pts)
 * - Relock rate (15 pts)
 * - Streak maintained (15 pts)
 */
class RecoveryScoreService
{
    public function computeForDate(User $user, Carbon $date): RecoveryScore
    {
        $dateStr = $date->toDateString();

        // Gather raw data
        $recoveredSeconds = $this->getRecoveredSeconds($user, $date);
        $screenSeconds    = $this->getScreenSeconds($user, $date);
        $challengeCount   = $this->getChallengeCompletions($user, $date);
        $emergencyCount   = $this->getEmergencyUnlocks($user, $date);
        $relockCount      = $this->getRelockCount($user, $date);
        $streakMaintained = $this->isStreakMaintained($user, $date);

        // Score components
        $recoveryRatio  = $screenSeconds > 0 ? min(1.0, $recoveredSeconds / $screenSeconds) : 0;
        $recoveryPoints = (int) ($recoveryRatio * 30);

        $challengePoints = min(20, $challengeCount * 5);

        $emergencyPenalty = min(20, $emergencyCount * 10);
        $emergencyPoints  = 20 - $emergencyPenalty;

        $relockPenalty = min(15, $relockCount * 5);
        $relockPoints  = 15 - $relockPenalty;

        $streakPoints = $streakMaintained ? 15 : 0;

        $score = $recoveryPoints + $challengePoints + $emergencyPoints + $relockPoints + $streakPoints;

        return RecoveryScore::updateOrCreate(
            ['user_id' => $user->id, 'date' => $dateStr],
            [
                'score'                 => $score,
                'recovered_minutes'     => (int) ($recoveredSeconds / 60),
                'challenge_completions' => $challengeCount,
                'emergency_unlocks'     => $emergencyCount,
                'relock_count'          => $relockCount,
                'discipline_ratio'      => $recoveryRatio,
            ]
        );
    }

    public function getScoreTrend(User $user, int $days = 30): array
    {
        return RecoveryScore::where('user_id', $user->id)
            ->where('date', '>=', now()->subDays($days)->toDateString())
            ->orderBy('date')
            ->get(['date', 'score'])
            ->map(fn($r) => ['date' => $r->date, 'score' => $r->score])
            ->toArray();
    }

    private function getRecoveredSeconds(User $user, Carbon $date): int
    {
        return $user->unlockEvents()
            ->whereDate('unlocked_at', $date)
            ->sum('reward_minutes') * 60;
    }

    private function getScreenSeconds(User $user, Carbon $date): int
    {
        return $user->usageLogs()
            ->where('date', $date->toDateString())
            ->sum('usage_seconds');
    }

    private function getChallengeCompletions(User $user, Carbon $date): int
    {
        return $user->challengeCompletions()
            ->where('result', 'completed')
            ->whereDate('completed_at', $date)
            ->count();
    }

    private function getEmergencyUnlocks(User $user, Carbon $date): int
    {
        return $user->emergencyUnlocks()
            ->whereDate('used_at', $date)
            ->count();
    }

    private function getRelockCount(User $user, Carbon $date): int
    {
        return $user->unlockEvents()
            ->whereDate('unlocked_at', $date)
            ->where('relocked', true)
            ->count();
    }

    private function isStreakMaintained(User $user, Carbon $date): bool
    {
        $streak = $user->streak;
        if (!$streak) return false;
        return $streak->last_streak_date === $date->toDateString();
    }
}
