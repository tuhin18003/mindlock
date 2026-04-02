<?php

namespace Database\Factories;

use App\Models\Challenge;
use App\Models\ChallengeCategory;
use Illuminate\Database\Eloquent\Factories\Factory;

class ChallengeFactory extends Factory
{
    protected $model = Challenge::class;

    public function definition(): array
    {
        return [
            'category_id'      => ChallengeCategory::factory(),
            'title'            => fake()->sentence(4),
            'description'      => fake()->paragraph(),
            'type'             => fake()->randomElement(['reflection', 'breathing', 'quiz', 'physical', 'mindfulness']),
            'difficulty'       => fake()->randomElement(['easy', 'medium', 'hard']),
            'reward_minutes'   => fake()->numberBetween(5, 30),
            'duration_seconds' => fake()->numberBetween(60, 600),
            'is_pro'           => false,
            'is_active'        => true,
            'sort_order'       => fake()->numberBetween(0, 50),
            'content'          => null,
        ];
    }

    public function pro(): static
    {
        return $this->state(fn (array $attributes) => [
            'is_pro' => true,
        ]);
    }

    public function inactive(): static
    {
        return $this->state(fn (array $attributes) => [
            'is_active' => false,
        ]);
    }

    public function reflection(): static
    {
        return $this->state(fn (array $attributes) => [
            'type'             => 'reflection',
            'duration_seconds' => 120,
        ]);
    }

    public function breathing(): static
    {
        return $this->state(fn (array $attributes) => [
            'type'             => 'breathing',
            'duration_seconds' => 180,
        ]);
    }
}
