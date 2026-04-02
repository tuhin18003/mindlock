<?php

namespace Database\Factories;

use App\Models\Entitlement;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

class EntitlementFactory extends Factory
{
    protected $model = Entitlement::class;

    public function definition(): array
    {
        return [
            'user_id'    => User::factory(),
            'tier'       => 'pro',
            'source'     => fake()->randomElement(['admin_grant', 'trial', 'subscription']),
            'status'     => 'active',
            'expires_at' => now()->addDays(30),
        ];
    }

    public function lifetime(): static
    {
        return $this->state(fn (array $attributes) => [
            'source'     => 'lifetime',
            'expires_at' => null,
        ]);
    }

    public function expired(): static
    {
        return $this->state(fn (array $attributes) => [
            'status'     => 'expired',
            'expires_at' => now()->subDay(),
        ]);
    }

    public function trial(): static
    {
        return $this->state(fn (array $attributes) => [
            'source'     => 'trial',
            'expires_at' => now()->addDays(7),
        ]);
    }

    public function adminGrant(): static
    {
        return $this->state(fn (array $attributes) => [
            'source'     => 'admin_grant',
            'expires_at' => now()->addYear(),
        ]);
    }
}
