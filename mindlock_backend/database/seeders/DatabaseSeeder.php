<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Seeder;
use Spatie\Permission\Models\Role;
use Spatie\Permission\Models\Permission;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        // Roles
        $adminRole = Role::firstOrCreate(['name' => 'admin', 'guard_name' => 'web']);
        $userRole  = Role::firstOrCreate(['name' => 'user', 'guard_name' => 'web']);

        // Permissions
        $permissions = [
            'manage_users',
            'manage_entitlements',
            'manage_challenges',
            'manage_feature_flags',
            'view_analytics',
            'manage_support',
        ];

        foreach ($permissions as $perm) {
            $p = Permission::firstOrCreate(['name' => $perm, 'guard_name' => 'web']);
            $adminRole->givePermissionTo($p);
        }

        // Seed admin user
        $admin = User::firstOrCreate(
            ['email' => 'admin@mindlock.app'],
            [
                'name'     => 'MindLock Admin',
                'password' => bcrypt('admin_password_change_me'),
                'status'   => 'active',
            ]
        );
        $admin->assignRole($adminRole);

        // Seed plans and challenges
        $this->call([
            PlansSeeder::class,
            ChallengesSeeder::class,
        ]);
    }
}
