<?php

namespace App\Policies;

use App\Models\User;

class UserPolicy
{
    /**
     * Admin can view any user profile.
     */
    public function viewAny(User $admin): bool
    {
        return $admin->hasRole('admin');
    }

    public function view(User $admin, User $target): bool
    {
        return $admin->hasRole('admin') || $admin->id === $target->id;
    }

    public function update(User $admin, User $target): bool
    {
        return $admin->hasRole('admin') || $admin->id === $target->id;
    }

    public function suspend(User $admin, User $target): bool
    {
        // Cannot suspend another admin
        if ($target->hasRole('admin')) {
            return false;
        }

        return $admin->hasRole('admin');
    }

    public function restore(User $admin, User $target): bool
    {
        return $admin->hasRole('admin');
    }

    public function delete(User $admin, User $target): bool
    {
        return $admin->hasRole('super_admin') && $admin->id !== $target->id;
    }
}
