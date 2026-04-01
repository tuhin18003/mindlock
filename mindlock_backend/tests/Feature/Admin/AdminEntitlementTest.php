<?php

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Spatie\Permission\Models\Role;

uses(RefreshDatabase::class);

beforeEach(function () {
    $adminRole = Role::firstOrCreate(['name' => 'admin', 'guard_name' => 'web']);
    $this->admin = User::factory()->create();
    $this->admin->assignRole($adminRole);
});

test('admin can grant pro access to a user', function () {
    $user = User::factory()->create();

    $this->actingAs($this->admin)
        ->postJson("/api/admin/entitlements/user/{$user->id}/grant-pro", [
            'source'     => 'admin_grant',
            'expires_at' => now()->addDays(30)->toIso8601String(),
            'notes'      => 'Test grant',
        ])
        ->assertOk()
        ->assertJsonPath('success', true);

    $this->assertDatabaseHas('entitlements', [
        'user_id' => $user->id,
        'tier'    => 'pro',
        'status'  => 'active',
        'source'  => 'admin_grant',
    ]);
});

test('admin can revoke pro access', function () {
    $user = User::factory()->create();
    app(\App\Services\EntitlementResolver::class)->grant($user, 'admin_grant');

    $this->actingAs($this->admin)
        ->postJson("/api/admin/entitlements/user/{$user->id}/revoke", [
            'notes' => 'Revoked for testing',
        ])
        ->assertOk();

    $this->assertDatabaseMissing('entitlements', [
        'user_id' => $user->id,
        'tier'    => 'pro',
        'status'  => 'active',
    ]);
});

test('non-admin cannot access admin routes', function () {
    $user = User::factory()->create();
    $target = User::factory()->create();

    $this->actingAs($user)
        ->postJson("/api/admin/entitlements/user/{$target->id}/grant-pro", [
            'source' => 'admin_grant',
        ])
        ->assertStatus(403);
});

test('audit log is created on admin grant', function () {
    $user = User::factory()->create();

    $this->actingAs($this->admin)
        ->postJson("/api/admin/entitlements/user/{$user->id}/grant-pro", [
            'source' => 'admin_grant',
        ]);

    $this->assertDatabaseHas('admin_audit_logs', [
        'admin_id'    => $this->admin->id,
        'action'      => 'grant_pro',
        'target_type' => 'user',
        'target_id'   => $user->id,
    ]);
});
