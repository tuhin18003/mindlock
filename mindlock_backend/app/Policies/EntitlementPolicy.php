<?php

namespace App\Policies;

use App\Models\Entitlement;
use App\Models\User;

class EntitlementPolicy
{
    public function viewAny(User $admin): bool
    {
        return $admin->hasRole('admin');
    }

    public function view(User $admin, Entitlement $entitlement): bool
    {
        return $admin->hasRole('admin') || $admin->id === $entitlement->user_id;
    }

    public function grant(User $admin): bool
    {
        return $admin->hasRole('admin');
    }

    public function revoke(User $admin, Entitlement $entitlement): bool
    {
        if (!$admin->hasRole('admin')) {
            return false;
        }

        // Cannot revoke a subscription-based entitlement from the admin panel
        // (must go through the billing provider)
        return in_array($entitlement->source, ['admin_grant', 'trial', 'coupon', 'lifetime']);
    }
}
