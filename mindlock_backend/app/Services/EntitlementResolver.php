<?php

namespace App\Services;

use App\Models\Entitlement;
use App\Models\User;
use Illuminate\Support\Carbon;

/**
 * EntitlementResolver — the single source of truth for Pro access.
 *
 * All feature gates must go through this service.
 * Never check billing rows directly in controllers or policies.
 */
class EntitlementResolver
{
    /**
     * Resolve the current active entitlement for a user.
     */
    public function resolve(User $user): ?Entitlement
    {
        return $user->entitlements()
            ->where('status', 'active')
            ->where(function ($q) {
                $q->whereNull('expires_at')
                  ->orWhere('expires_at', '>', now());
            })
            ->orderByRaw("FIELD(source, 'lifetime', 'admin_grant', 'subscription', 'purchase', 'trial', 'coupon', 'referral')")
            ->orderByDesc('created_at')
            ->first();
    }

    /**
     * Check if the user has Pro access.
     */
    public function isPro(User $user): bool
    {
        $entitlement = $this->resolve($user);
        return $entitlement?->tier === 'pro';
    }

    /**
     * Grant Pro access to a user (admin grant, trial, coupon, etc.)
     */
    public function grant(
        User $user,
        string $source,
        ?int $planId = null,
        ?Carbon $expiresAt = null,
        ?int $grantedBy = null,
        ?string $notes = null,
        ?string $referenceId = null,
    ): Entitlement {
        // Deactivate any existing active entitlements of same tier
        $this->deactivateExistingGrants($user, $source);

        $entitlement = Entitlement::create([
            'user_id'      => $user->id,
            'plan_id'      => $planId,
            'tier'         => 'pro',
            'source'       => $source,
            'status'       => 'active',
            'starts_at'    => now(),
            'expires_at'   => $expiresAt,
            'granted_by'   => $grantedBy,
            'notes'        => $notes,
            'reference_id' => $referenceId,
        ]);

        $this->recordHistory($user, $entitlement, 'activated', $source, $grantedBy);

        return $entitlement;
    }

    /**
     * Revoke Pro access.
     */
    public function revoke(User $user, ?int $revokedBy = null, ?string $notes = null): void
    {
        $entitlements = $user->entitlements()
            ->where('status', 'active')
            ->where('tier', 'pro')
            ->get();

        foreach ($entitlements as $entitlement) {
            $entitlement->update([
                'status' => 'revoked',
                'notes'  => $notes,
            ]);
            $this->recordHistory($user, $entitlement, 'revoked', 'admin_grant', $revokedBy, $notes);
        }
    }

    /**
     * Grant a timed trial.
     */
    public function grantTrial(User $user, int $trialDays = 7): Entitlement
    {
        return $this->grant(
            user: $user,
            source: 'trial',
            expiresAt: now()->addDays($trialDays),
        );
    }

    /**
     * Grant lifetime Pro.
     */
    public function grantLifetime(User $user, ?int $grantedBy = null, ?string $notes = null): Entitlement
    {
        return $this->grant(
            user: $user,
            source: 'lifetime',
            expiresAt: null, // null = never expires
            grantedBy: $grantedBy,
            notes: $notes,
        );
    }

    /**
     * Check if user has already used their trial.
     */
    public function hasUsedTrial(User $user): bool
    {
        return $user->entitlements()
            ->where('source', 'trial')
            ->exists();
    }

    /**
     * Get entitlement summary for API responses.
     */
    public function getSummary(User $user): array
    {
        $entitlement = $this->resolve($user);

        return [
            'tier'         => $entitlement?->tier ?? 'free',
            'is_pro'       => $entitlement?->tier === 'pro',
            'source'       => $entitlement?->source ?? null,
            'status'       => $entitlement?->status ?? 'none',
            'expires_at'   => $entitlement?->expires_at?->toIso8601String(),
            'is_lifetime'  => $entitlement?->isLifetime() ?? false,
            'days_remaining' => $entitlement?->daysRemaining(),
            'trial_available' => !$this->hasUsedTrial($user),
        ];
    }

    /**
     * Handle subscription renewal/update from billing.
     */
    public function syncFromSubscription(
        User $user,
        string $storeSubscriptionId,
        ?Carbon $expiresAt,
        string $status,
        ?int $planId = null,
    ): Entitlement {
        // Find or update the subscription-linked entitlement
        $entitlement = $user->entitlements()
            ->where('source', 'subscription')
            ->where('reference_id', $storeSubscriptionId)
            ->first();

        if ($entitlement) {
            $entitlement->update([
                'status'     => $status === 'active' ? 'active' : ($status === 'expired' ? 'expired' : 'revoked'),
                'expires_at' => $expiresAt,
            ]);
        } else {
            $entitlement = $this->grant(
                user: $user,
                source: 'subscription',
                planId: $planId,
                expiresAt: $expiresAt,
                referenceId: $storeSubscriptionId,
            );
        }

        return $entitlement;
    }

    private function deactivateExistingGrants(User $user, string $newSource): void
    {
        // For admin grants, only deactivate other admin grants (not subscriptions)
        $sourcesToDeactivate = match ($newSource) {
            'admin_grant' => ['admin_grant'],
            'trial'       => ['trial'],
            default       => [],
        };

        if (!empty($sourcesToDeactivate)) {
            $user->entitlements()
                ->whereIn('source', $sourcesToDeactivate)
                ->where('status', 'active')
                ->update(['status' => 'revoked']);
        }
    }

    private function recordHistory(
        User $user,
        Entitlement $entitlement,
        string $event,
        string $source,
        ?int $performedBy = null,
        ?string $notes = null,
    ): void {
        $entitlement->histories()->create([
            'user_id'      => $user->id,
            'event'        => $event,
            'from_tier'    => $event === 'activated' ? 'free' : 'pro',
            'to_tier'      => $event === 'activated' ? 'pro' : 'free',
            'source'       => $source,
            'performed_by' => $performedBy,
            'notes'        => $notes,
            'occurred_at'  => now(),
        ]);
    }
}
