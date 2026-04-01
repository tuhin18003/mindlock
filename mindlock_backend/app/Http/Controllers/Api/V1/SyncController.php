<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Jobs\AggregateUserDailySummaryJob;
use App\Jobs\ComputeRecoveryScoreJob;
use App\Jobs\UpdateStreakJob;
use App\Services\UsageSyncService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class SyncController extends Controller
{
    public function __construct(
        private readonly UsageSyncService $syncService,
    ) {}

    public function syncMonitoredApps(Request $request): JsonResponse
    {
        $request->validate([
            'apps'                   => 'required|array',
            'apps.*.package_name'    => 'required|string',
            'apps.*.app_name'        => 'required|string',
            'apps.*.category'        => 'nullable|string',
            'apps.*.is_tracked'      => 'boolean',
            'apps.*.is_locked'       => 'boolean',
            'apps.*.strict_mode'     => 'boolean',
        ]);

        $user = $request->user();
        $this->syncService->syncMonitoredApps($user, $request->apps);

        return response()->json(['success' => true, 'synced' => count($request->apps)]);
    }

    public function syncUsageLogs(Request $request): JsonResponse
    {
        $request->validate([
            'device_id'              => 'required|string',
            'logs'                   => 'required|array',
            'logs.*.package_name'    => 'required|string',
            'logs.*.date'            => 'required|date_format:Y-m-d',
            'logs.*.usage_seconds'   => 'required|integer|min:0',
            'logs.*.open_count'      => 'nullable|integer|min:0',
            'logs.*.category'        => 'nullable|string',
        ]);

        $user = $request->user();
        $this->syncService->syncUsageLogs($user, $request->device_id, $request->logs);

        // Trigger background aggregation
        AggregateUserDailySummaryJob::dispatch($user->id)->onQueue('aggregation');

        return response()->json(['success' => true, 'synced' => count($request->logs)]);
    }

    public function syncLockEvents(Request $request): JsonResponse
    {
        $request->validate([
            'device_id'                     => 'required|string',
            'events'                        => 'required|array',
            'events.*.package_name'         => 'required|string',
            'events.*.usage_seconds_at_lock' => 'required|integer',
            'events.*.limit_seconds'        => 'required|integer',
            'events.*.locked_at'            => 'required|date',
            'events.*.local_event_id'       => 'nullable|string',
            'events.*.strict_mode'          => 'nullable|boolean',
            'events.*.trigger_reason'       => 'nullable|string',
        ]);

        $user = $request->user();
        $synced = $this->syncService->syncLockEvents($user, $request->device_id, $request->events);

        return response()->json(['success' => true, 'synced_ids' => $synced]);
    }

    public function syncUnlockEvents(Request $request): JsonResponse
    {
        $request->validate([
            'device_id'                  => 'required|string',
            'events'                     => 'required|array',
            'events.*.package_name'      => 'required|string',
            'events.*.method'            => 'required|string',
            'events.*.unlocked_at'       => 'required|date',
            'events.*.local_event_id'    => 'nullable|string',
            'events.*.reward_minutes'    => 'nullable|integer',
            'events.*.was_emergency'     => 'nullable|boolean',
            'events.*.relocked'          => 'nullable|boolean',
            'events.*.lock_event_local_id' => 'nullable|string',
        ]);

        $user = $request->user();
        $synced = $this->syncService->syncUnlockEvents($user, $request->device_id, $request->events);

        // Trigger score/streak recalculation
        ComputeRecoveryScoreJob::dispatch($user->id)->onQueue('analytics');
        UpdateStreakJob::dispatch($user->id)->onQueue('analytics');

        return response()->json(['success' => true, 'synced_ids' => $synced]);
    }

    public function syncChallengeCompletions(Request $request): JsonResponse
    {
        $request->validate([
            'device_id'                    => 'required|string',
            'completions'                  => 'required|array',
            'completions.*.challenge_id'   => 'required|integer',
            'completions.*.result'         => 'required|in:completed,skipped,failed',
            'completions.*.completed_at'   => 'required|date',
            'completions.*.local_event_id' => 'nullable|string',
            'completions.*.package_name'   => 'nullable|string',
            'completions.*.reward_granted_minutes' => 'nullable|integer',
            'completions.*.user_response'  => 'nullable|string',
        ]);

        $user = $request->user();
        $synced = [];

        foreach ($request->completions as $completion) {
            $localId = $completion['local_event_id'] ?? null;

            if ($localId && \App\Models\ChallengeCompletion::where('local_event_id', $localId)->exists()) {
                continue;
            }

            $record = $user->challengeCompletions()->create([
                'challenge_id'           => $completion['challenge_id'],
                'device_id'              => $request->device_id,
                'package_name'           => $completion['package_name'] ?? null,
                'result'                 => $completion['result'],
                'time_seconds'           => $completion['time_seconds'] ?? null,
                'reward_granted_minutes' => $completion['reward_granted_minutes'] ?? 0,
                'user_response'          => $completion['user_response'] ?? null,
                'local_event_id'         => $localId,
                'completed_at'           => $completion['completed_at'],
            ]);

            $synced[] = $record->id;
        }

        return response()->json(['success' => true, 'synced_ids' => $synced]);
    }

    public function todaySummary(Request $request): JsonResponse
    {
        $user = $request->user();
        $deviceId = $request->header('X-Device-ID', '');

        $summary = $this->syncService->getTodaySummary($user, $deviceId);

        return response()->json(['success' => true, 'data' => $summary]);
    }
}
