<?php

namespace App\Jobs;

use App\Models\User;
use App\Services\RecoveryScoreService;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;

class ComputeRecoveryScoreJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public int $tries = 3;

    public function __construct(public readonly int $userId) {}

    public function handle(RecoveryScoreService $service): void
    {
        $user = User::findOrFail($this->userId);
        $service->computeForDate($user, now());
    }
}
