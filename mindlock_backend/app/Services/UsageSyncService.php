<?php

namespace App\Services;

use App\Models\LockEvent;
use App\Models\MonitoredApp;
use App\Models\UnlockEvent;
use App\Models\UsageLog;
use App\Models\User;
use Illuminate\Support\Carbon;

class UsageSyncService
{
    /**
     * Sync monitored apps list from device.
     */
    public function syncMonitoredApps(User $user, array $apps): void
    {
        foreach ($apps as $app) {
            MonitoredApp::updateOrCreate(
                ['user_id' => $user->id, 'package_name' => $app['package_name']],
                [
                    'app_name'    => $app['app_name'],
                    'category'    => $app['category'] ?? null,
                    'is_tracked'  => $app['is_tracked'] ?? true,
                    'is_locked'   => $app['is_locked'] ?? false,
                    'strict_mode' => $app['strict_mode'] ?? false,
                ]
            );
        }
    }

    /**
     * Sync usage logs from device. Uses upsert for efficiency.
     */
    public function syncUsageLogs(User $user, string $deviceId, array $logs): void
    {
        $records = array_map(fn($log) => [
            'user_id'        => $user->id,
            'device_id'      => $deviceId,
            'package_name'   => $log['package_name'],
            'date'           => $log['date'],
            'usage_seconds'  => $log['usage_seconds'],
            'open_count'     => $log['open_count'] ?? 0,
            'category'       => $log['category'] ?? null,
            'synced_at'      => now(),
            'created_at'     => now(),
            'updated_at'     => now(),
        ], $logs);

        UsageLog::upsert(
            $records,
            ['user_id', 'device_id', 'package_name', 'date'],
            ['usage_seconds', 'open_count', 'category', 'synced_at', 'updated_at']
        );
    }

    /**
     * Sync lock events from device (idempotent via local_event_id).
     */
    public function syncLockEvents(User $user, string $deviceId, array $events): array
    {
        $synced = [];

        foreach ($events as $event) {
            $localId = $event['local_event_id'] ?? null;

            // Skip if already synced
            if ($localId && LockEvent::where('local_event_id', $localId)->exists()) {
                continue;
            }

            $record = LockEvent::create([
                'user_id'                => $user->id,
                'device_id'              => $deviceId,
                'package_name'           => $event['package_name'],
                'app_name'               => $event['app_name'] ?? null,
                'usage_seconds_at_lock'  => $event['usage_seconds_at_lock'],
                'limit_seconds'          => $event['limit_seconds'],
                'strict_mode'            => $event['strict_mode'] ?? false,
                'trigger_reason'         => $event['trigger_reason'] ?? 'limit_reached',
                'locked_at'              => Carbon::parse($event['locked_at']),
                'local_event_id'         => $localId,
            ]);

            $synced[] = $record->id;
        }

        return $synced;
    }

    /**
     * Sync unlock events.
     */
    public function syncUnlockEvents(User $user, string $deviceId, array $events): array
    {
        $synced = [];

        foreach ($events as $event) {
            $localId = $event['local_event_id'] ?? null;

            if ($localId && UnlockEvent::where('local_event_id', $localId)->exists()) {
                continue;
            }

            // Try to match lock event
            $lockEventId = null;
            if (!empty($event['lock_event_local_id'])) {
                $lockEventId = LockEvent::where('local_event_id', $event['lock_event_local_id'])
                    ->value('id');
            }

            $record = UnlockEvent::create([
                'user_id'         => $user->id,
                'lock_event_id'   => $lockEventId,
                'device_id'       => $deviceId,
                'package_name'    => $event['package_name'],
                'method'          => $event['method'],
                'reward_minutes'  => $event['reward_minutes'] ?? 0,
                'was_emergency'   => $event['was_emergency'] ?? false,
                'relocked'        => $event['relocked'] ?? false,
                'relock_minutes'  => $event['relock_minutes'] ?? null,
                'local_event_id'  => $localId,
                'unlocked_at'     => Carbon::parse($event['unlocked_at']),
            ]);

            $synced[] = $record->id;
        }

        return $synced;
    }

    /**
     * Get today's summary for a user.
     */
    public function getTodaySummary(User $user, string $deviceId): array
    {
        $today = now()->toDateString();

        $screenSeconds = UsageLog::where('user_id', $user->id)
            ->where('date', $today)
            ->sum('usage_seconds');

        $lockCount = LockEvent::where('user_id', $user->id)
            ->whereDate('locked_at', today())
            ->count();

        $recoveredMinutes = UnlockEvent::where('user_id', $user->id)
            ->whereDate('unlocked_at', today())
            ->sum('reward_minutes');

        $emergencyCount = $user->emergencyUnlocks()
            ->whereDate('used_at', today())
            ->count();

        $topApp = UsageLog::where('user_id', $user->id)
            ->where('date', $today)
            ->orderByDesc('usage_seconds')
            ->value('package_name');

        return [
            'date'               => $today,
            'screen_time_seconds'=> $screenSeconds,
            'lock_count'         => $lockCount,
            'recovered_minutes'  => $recoveredMinutes,
            'emergency_unlocks'  => $emergencyCount,
            'top_distraction_app'=> $topApp,
        ];
    }
}
