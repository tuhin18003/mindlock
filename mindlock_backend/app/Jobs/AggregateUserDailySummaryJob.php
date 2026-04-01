<?php

namespace App\Jobs;

use App\Models\User;
use App\Services\AnalyticsAggregationService;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Carbon;

class AggregateUserDailySummaryJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public int $tries = 3;
    public int $timeout = 60;

    public function __construct(
        public readonly int $userId,
        public readonly ?string $date = null,
    ) {}

    public function handle(AnalyticsAggregationService $service): void
    {
        $user = User::findOrFail($this->userId);
        $date = $this->date ? Carbon::parse($this->date) : now();
        $service->aggregateDailySummary($user, $date);
    }
}
