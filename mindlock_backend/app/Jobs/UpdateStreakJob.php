<?php

namespace App\Jobs;

use App\Models\Streak;
use App\Models\User;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;

class UpdateStreakJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public function __construct(public readonly int $userId) {}

    public function handle(): void
    {
        $user   = User::findOrFail($this->userId);
        $streak = $user->streak ?? Streak::create(['user_id' => $user->id]);
        $today  = now()->toDateString();

        // Already updated today
        if ($streak->last_streak_date === $today) {
            return;
        }

        $yesterday = now()->subDay()->toDateString();
        $isConsecutive = $streak->last_streak_date === $yesterday;

        // Check if user actually did something meaningful today (at least 1 challenge or no emergency unlocks)
        $challengeCount = $user->challengeCompletions()
            ->where('result', 'completed')
            ->whereDate('completed_at', today())
            ->count();

        $emergencyCount = $user->emergencyUnlocks()
            ->whereDate('used_at', today())
            ->count();

        $meritedStreak = $challengeCount > 0 || $emergencyCount === 0;

        if ($meritedStreak) {
            $newStreak = $isConsecutive ? $streak->current_streak + 1 : 1;
            $streak->update([
                'current_streak'  => $newStreak,
                'longest_streak'  => max($newStreak, $streak->longest_streak),
                'last_streak_date'=> $today,
                'streak_start_date' => $isConsecutive ? $streak->streak_start_date : $today,
                'total_streak_days' => $streak->total_streak_days + 1,
            ]);
        }
    }
}
