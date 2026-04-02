<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;

class PruneOldAnalyticsEvents extends Command
{
    protected $signature   = 'mindlock:prune-analytics {--days=90 : Delete events older than N days}';
    protected $description = 'Prune raw analytics events older than the retention window.';

    public function handle(): int
    {
        $days   = (int) $this->option('days');
        $cutoff = now()->subDays($days);

        $deleted = DB::table('analytics_events')
            ->where('occurred_at', '<', $cutoff)
            ->delete();

        $this->info("Pruned {$deleted} analytics events older than {$days} days.");
        return self::SUCCESS;
    }
}
