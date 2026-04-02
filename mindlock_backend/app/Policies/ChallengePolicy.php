<?php

namespace App\Policies;

use App\Models\Challenge;
use App\Models\User;

class ChallengePolicy
{
    public function viewAny(User $user): bool
    {
        return true; // All authenticated users can list challenges
    }

    public function view(User $user, Challenge $challenge): bool
    {
        // Free challenges visible to all; Pro challenges require entitlement
        if (!$challenge->is_pro) {
            return true;
        }

        return $user->isPro();
    }

    public function create(User $admin): bool
    {
        return $admin->hasRole('admin');
    }

    public function update(User $admin, Challenge $challenge): bool
    {
        return $admin->hasRole('admin');
    }

    public function delete(User $admin, Challenge $challenge): bool
    {
        return $admin->hasRole('admin');
    }
}
