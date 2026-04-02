<?php

namespace Database\Factories;

use App\Models\ChallengeCategory;
use Illuminate\Database\Eloquent\Factories\Factory;

class ChallengeCategoryFactory extends Factory
{
    protected $model = ChallengeCategory::class;

    public function definition(): array
    {
        return [
            'name'        => fake()->unique()->words(2, true),
            'description' => fake()->sentence(),
            'icon'        => fake()->randomElement(['🧘', '💪', '🧠', '🌬️', '📖']),
            'sort_order'  => fake()->numberBetween(0, 10),
            'is_active'   => true,
        ];
    }

    public function inactive(): static
    {
        return $this->state(fn (array $attributes) => [
            'is_active' => false,
        ]);
    }
}
