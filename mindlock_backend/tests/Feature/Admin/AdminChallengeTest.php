<?php

use App\Models\Challenge;
use App\Models\ChallengeCategory;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Spatie\Permission\Models\Role;

uses(RefreshDatabase::class);

beforeEach(function () {
    Role::firstOrCreate(['name' => 'admin', 'guard_name' => 'web']);
    $this->admin = User::factory()->create();
    $this->admin->assignRole('admin');

    $this->category = ChallengeCategory::factory()->create([
        'slug' => 'reflection',
        'name' => 'Reflection',
    ]);
});

test('admin can list challenges', function () {
    Challenge::factory()->count(5)->create(['category_id' => $this->category->id]);

    $this->actingAs($this->admin)
        ->getJson('/api/admin/challenges')
        ->assertOk()
        ->assertJsonStructure(['success', 'data']);
});

test('admin can create a challenge', function () {
    $this->actingAs($this->admin)
        ->postJson('/api/admin/challenges', [
            'category_id'       => $this->category->id,
            'slug'              => 'test-challenge',
            'title'             => 'Test Challenge',
            'description'       => 'A test challenge',
            'type'              => 'reflection',
            'difficulty'        => 'easy',
            'reward_minutes'    => 5,
            'estimated_seconds' => 60,
            'is_pro'            => false,
            'is_active'         => true,
        ])
        ->assertStatus(201)
        ->assertJsonPath('data.slug', 'test-challenge');

    $this->assertDatabaseHas('challenges', ['slug' => 'test-challenge']);
});

test('admin can update a challenge', function () {
    $challenge = Challenge::factory()->create(['category_id' => $this->category->id]);

    $this->actingAs($this->admin)
        ->putJson("/api/admin/challenges/{$challenge->id}", [
            'title'      => 'Updated Title',
            'is_active'  => false,
        ])
        ->assertOk()
        ->assertJsonPath('data.title', 'Updated Title');
});

test('admin destroy deactivates not deletes challenge', function () {
    $challenge = Challenge::factory()->create(['category_id' => $this->category->id]);

    $this->actingAs($this->admin)
        ->deleteJson("/api/admin/challenges/{$challenge->id}")
        ->assertOk();

    $this->assertDatabaseHas('challenges', ['id' => $challenge->id, 'is_active' => false]);
});

test('admin can toggle feature flag', function () {
    $this->actingAs($this->admin)
        ->postJson('/api/admin/feature-flags', [
            'key'          => 'test_flag',
            'name'         => 'Test Flag',
            'is_enabled'   => true,
            'rollout_type' => 'everyone',
        ])
        ->assertStatus(201)
        ->assertJsonPath('data.key', 'test_flag');

    $this->assertDatabaseHas('feature_flags', ['key' => 'test_flag', 'is_enabled' => true]);
});
