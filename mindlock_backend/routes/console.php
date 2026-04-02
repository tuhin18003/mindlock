<?php

use App\Console\Commands\AggregateAnalyticsDailySummaries;
use App\Console\Commands\ComputeRecoveryScores;
use App\Console\Commands\ExpireEntitlements;
use App\Console\Commands\PruneOldAnalyticsEvents;
use Illuminate\Support\Facades\Schedule;

// Aggregate daily usage summaries — runs just after midnight
Schedule::command(AggregateAnalyticsDailySummaries::class)->dailyAt('00:15');

// Compute recovery scores for yesterday — runs at 00:30
Schedule::command(ComputeRecoveryScores::class)->dailyAt('00:30');

// Check and expire overdue entitlements — every hour
Schedule::command(ExpireEntitlements::class)->hourly();

// Prune raw analytics events older than 90 days — weekly
Schedule::command(PruneOldAnalyticsEvents::class)->weekly()->sundays()->at('03:00');
