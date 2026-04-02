<?php

namespace Database\Factories;

use App\Models\MonitoredApp;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

class MonitoredAppFactory extends Factory
{
    protected $model = MonitoredApp::class;

    private static array $apps = [
        ['com.instagram.android', 'Instagram'],
        ['com.facebook.katana', 'Facebook'],
        ['com.twitter.android', 'Twitter'],
        ['com.zhiliaoapp.musically', 'TikTok'],
        ['com.snapchat.android', 'Snapchat'],
        ['com.reddit.frontpage', 'Reddit'],
        ['com.youtube.android', 'YouTube'],
    ];

    public function definition(): array
    {
        $app = fake()->randomElement(self::$apps);

        return [
            'user_id'              => User::factory(),
            'package_name'         => $app[0],
            'app_name'             => $app[1],
            'daily_limit_minutes'  => fake()->randomElement([30, 60, 90, 120, null]),
            'is_locked'            => false,
            'lock_mode'            => 'soft',
        ];
    }

    public function locked(): static
    {
        return $this->state(fn (array $attributes) => [
            'is_locked' => true,
        ]);
    }

    public function withLimit(int $minutes): static
    {
        return $this->state(fn (array $attributes) => [
            'daily_limit_minutes' => $minutes,
        ]);
    }
}
