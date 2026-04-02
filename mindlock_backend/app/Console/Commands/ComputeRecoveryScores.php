<?php

namespace App\Console\Commands;

use App\Models\User;
use App\Services\RecoveryScoreService;
use Illuminate\Console\Command;
use Illuminate\Support\Carbon;

class ComputeRecoveryScores extends Command
{
    protected $signature   = 'mindlock:compute-scores {--date= : Date to compute (YYYY-MM-DD, defaults to yesterday)}';
    protected $description = 'Compute recovery scores for all active users.';

    public function handle(RecoveryScoreService $service): int
    {
        $date = $this->option('date')
            ? Carbon::parse($this->option('date'))
            : now()->subDay();

        $this->info("Computing recovery scores for {$date->toDateString()}...");

        $count = 0;
        User::where('status', 'active')->chunk(200, function ($users) use ($service, $date, &$count) {
            foreach ($users as $user) {
                try {
                    $service->computeForDate($user, $date);
                    $count++;
                } catch (\Throwable $e) {
                    $this->error("Failed for user {$user->id}: {$e->getMessage()}");
                }
            }
        });

        $this->info("Done. Computed {$count} scores.");
        return self::SUCCESS;
    }
}
