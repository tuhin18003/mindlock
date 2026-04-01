<?php

use App\Models\Plan;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(RefreshDatabase::class);

beforeEach(function () {
    Plan::factory()->create(['slug' => 'free', 'tier' => 'free']);
});

test('user can register', function () {
    $response = $this->postJson('/api/v1/auth/register', [
        'name'                  => 'Test User',
        'email'                 => 'test@example.com',
        'password'              => 'password123',
        'password_confirmation' => 'password123',
        'timezone'              => 'UTC',
    ]);

    $response->assertStatus(201)
        ->assertJsonPath('success', true)
        ->assertJsonStructure([
            'data' => ['user', 'token', 'entitlement', 'gates'],
        ]);

    $this->assertDatabaseHas('users', ['email' => 'test@example.com']);
});

test('user can login with correct credentials', function () {
    $user = User::factory()->create(['password' => bcrypt('password123')]);

    $response = $this->postJson('/api/v1/auth/login', [
        'email'    => $user->email,
        'password' => 'password123',
    ]);

    $response->assertOk()
        ->assertJsonPath('success', true)
        ->assertJsonStructure(['data' => ['token', 'entitlement']]);
});

test('login fails with wrong password', function () {
    $user = User::factory()->create(['password' => bcrypt('correct')]);

    $this->postJson('/api/v1/auth/login', [
        'email'    => $user->email,
        'password' => 'wrong',
    ])->assertStatus(422);
});

test('authenticated user can get their profile', function () {
    $user = User::factory()->create();

    $this->actingAs($user)->getJson('/api/v1/auth/me')
        ->assertOk()
        ->assertJsonPath('data.user.email', $user->email);
});

test('unauthenticated request to protected route returns 401', function () {
    $this->getJson('/api/v1/auth/me')->assertStatus(401);
});
