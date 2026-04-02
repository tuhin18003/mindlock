<?php

namespace App\Console\Commands;

use App\Models\Entitlement;
use App\Notifications\EntitlementExpiredNotification;
use Illuminate\Console\Command;

class ExpireEntitlements extends Command
{
    protected $signature   = 'mindlock:expire-entitlements';
    protected $description = 'Mark overdue entitlements as expired and notify users.';

    public function handle(): int
    {
        // Find active Pro entitlements that have passed their expiry
        $expired = Entitlement::where('status', 'active')
            ->where('tier', 'pro')
            ->whereNotNull('expires_at')
            ->where('expires_at', '<=', now())
            ->get();

        $count = 0;
        foreach ($expired as $entitlement) {
            $entitlement->update(['status' => 'expired']);

            // Record history
            $entitlement->histories()->create([
                'user_id'     => $entitlement->user_id,
                'event'       => 'expired',
                'from_tier'   => 'pro',
                'to_tier'     => 'free',
                'source'      => 'system',
                'occurred_at' => now(),
            ]);

            // Notify user
            try {
                $entitlement->user->notify(new EntitlementExpiredNotification($entitlement));
            } catch (\Throwable) {
                // Non-fatal — continue
            }

            $count++;
        }

        if ($count > 0) {
            $this->info("Expired {$count} entitlements.");
        }

        // Also warn about entitlements expiring within 3 days
        $soonExpiring = Entitlement::where('status', 'active')
            ->where('tier', 'pro')
            ->whereNotNull('expires_at')
            ->whereBetween('expires_at', [now(), now()->addDays(3)])
            ->get();

        foreach ($soonExpiring as $entitlement) {
            try {
                $entitlement->user->notify(
                    new \App\Notifications\EntitlementExpiringNotification($entitlement)
                );
            } catch (\Throwable) {}
        }

        return self::SUCCESS;
    }
}
