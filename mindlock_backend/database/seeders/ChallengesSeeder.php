<?php

namespace Database\Seeders;

use App\Models\Challenge;
use App\Models\ChallengeCategory;
use Illuminate\Database\Seeder;

class ChallengesSeeder extends Seeder
{
    public function run(): void
    {
        $categories = [
            ['slug' => 'reflection', 'name' => 'Reflection', 'icon' => 'psychology', 'color' => '#3ECFCF'],
            ['slug' => 'learning',   'name' => 'Learning',   'icon' => 'menu_book',   'color' => '#6C63FF'],
            ['slug' => 'mindfulness','name' => 'Mindfulness','icon' => 'spa',          'color' => '#4CAF50'],
            ['slug' => 'challenge',  'name' => 'Challenge',  'icon' => 'fitness_center','color' => '#FF9800'],
            ['slug' => 'habit',      'name' => 'Habit',      'icon' => 'check_circle', 'color' => '#FF6B6B'],
        ];

        $categoryMap = [];
        foreach ($categories as $cat) {
            $category = ChallengeCategory::updateOrCreate(['slug' => $cat['slug']], [
                ...$cat,
                'is_active'  => true,
                'sort_order' => 0,
            ]);
            $categoryMap[$cat['slug']] = $category->id;
        }

        $challenges = [
            // Reflection challenges (free)
            [
                'category_id' => $categoryMap['reflection'],
                'slug' => 'why_are_you_opening',
                'title' => 'Why are you opening this?',
                'description' => 'Pause and answer honestly.',
                'type' => 'reflection',
                'content' => 'What are you actually looking for right now? Boredom? Comfort? Information? Type your honest answer.',
                'difficulty' => 'easy',
                'reward_minutes' => 5,
                'estimated_seconds' => 30,
                'is_pro' => false,
                'is_active' => true,
                'goal' => 'awareness',
            ],
            [
                'category_id' => $categoryMap['reflection'],
                'slug' => 'what_could_you_do_instead',
                'title' => 'What else could you do?',
                'description' => 'Name one better use of this time.',
                'type' => 'reflection',
                'content' => 'Name one thing you could do in the next 5 minutes that you\'d feel better about than opening this app.',
                'difficulty' => 'easy',
                'reward_minutes' => 5,
                'estimated_seconds' => 30,
                'is_pro' => false,
                'is_active' => true,
                'goal' => 'awareness',
            ],
            // Learning challenges (free)
            [
                'category_id' => $categoryMap['learning'],
                'slug' => 'read_one_paragraph',
                'title' => 'Read Something Real',
                'description' => 'Read 1 paragraph of something meaningful.',
                'type' => 'learning_task',
                'content' => 'Open a book, article, or documentation and read at least one full paragraph. Come back when done.',
                'difficulty' => 'easy',
                'reward_minutes' => 10,
                'estimated_seconds' => 120,
                'is_pro' => false,
                'is_active' => true,
                'goal' => 'commitment',
            ],
            // Mindfulness (free)
            [
                'category_id' => $categoryMap['mindfulness'],
                'slug' => 'deep_breath',
                'title' => '5 Deep Breaths',
                'description' => 'Take 5 slow, full breaths.',
                'type' => 'mini_challenge',
                'content' => 'Breathe in slowly for 4 counts. Hold for 4. Out for 4. Repeat 5 times. Then decide if you still want to open the app.',
                'difficulty' => 'easy',
                'reward_minutes' => 5,
                'estimated_seconds' => 60,
                'is_pro' => false,
                'is_active' => true,
                'goal' => 'regulation',
            ],
            // Pro challenges
            [
                'category_id' => $categoryMap['challenge'],
                'slug' => 'write_your_goal',
                'title' => 'Write Your Main Goal',
                'description' => 'Write your most important goal right now.',
                'type' => 'reflection',
                'content' => 'Write your single most important goal for this week. Does opening this app help you get there?',
                'difficulty' => 'medium',
                'reward_minutes' => 10,
                'estimated_seconds' => 60,
                'is_pro' => true,
                'is_active' => true,
                'goal' => 'commitment',
            ],
            [
                'category_id' => $categoryMap['habit'],
                'slug' => 'drink_water',
                'title' => 'Drink a Glass of Water',
                'description' => 'Do one simple healthy habit first.',
                'type' => 'habit_task',
                'content' => 'Go get a glass of water. Drink it fully. Come back when done. This pause is intentional.',
                'difficulty' => 'easy',
                'reward_minutes' => 5,
                'estimated_seconds' => 60,
                'is_pro' => false,
                'is_active' => true,
                'goal' => 'pattern_interrupt',
            ],
            [
                'category_id' => $categoryMap['challenge'],
                'slug' => 'mood_check',
                'title' => 'Check Your Mood',
                'description' => 'What emotional state are you in?',
                'type' => 'reflection',
                'content' => 'How are you feeling right now? Choose: Bored / Stressed / Lonely / Procrastinating / Intentional need. What\'s the real reason?',
                'difficulty' => 'easy',
                'reward_minutes' => 5,
                'estimated_seconds' => 30,
                'is_pro' => true,
                'is_active' => true,
                'goal' => 'awareness',
            ],
        ];

        foreach ($challenges as $challenge) {
            Challenge::updateOrCreate(['slug' => $challenge['slug']], $challenge);
        }
    }
}
