<?php

namespace App\Console\Commands;

use App\Models\User;
use App\Services\AnalyticsAggregationService;
use Illuminate\Console\Command;
use Illuminate\Support\Carbon;

class AggregateAnalyticsDailySummaries extends Command
{
    protected $signature   = 'mindlock:aggregate-summaries {--date= : Date to aggregate (YYYY-MM-DD, defaults to yesterday)}';
    protected $description = 'Aggregate daily analytics summaries for all active users.';

    public function handle(AnalyticsAggregationService $service): int
    {
        $date = $this->option('date')
            ? Carbon::parse($this->option('date'))
            : now()->subDay();

        $this->info("Aggregating summaries for {$date->toDateString()}...");

        $bar   = $this->output->createProgressBar(User::count());
        $count = 0;

        User::where('status', 'active')
            ->whereHas('usageLogs', fn($q) => $q->where('date', $date->toDateString()))
            ->chunk(100, function ($users) use ($service, $date, $bar, &$count) {
                foreach ($users as $user) {
                    try {
                        $service->aggregateDailySummary($user, $date);
                        $count++;
                    } catch (\Throwable $e) {
                        $this->error("Failed for user {$user->id}: {$e->getMessage()}");
                    }
                    $bar->advance();
                }
            });

        $bar->finish();
        $this->newLine();
        $this->info("Done. Aggregated {$count} user summaries.");

        return self::SUCCESS;
    }
}
