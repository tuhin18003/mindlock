<?php

namespace Database\Seeders;

use App\Models\Plan;
use Illuminate\Database\Seeder;

class PlansSeeder extends Seeder
{
    public function run(): void
    {
        $plans = [
            [
                'slug'          => 'free',
                'name'          => 'Free',
                'description'   => 'Core discipline features',
                'tier'          => 'free',
                'billing_cycle' => 'none',
                'price'         => 0.00,
                'currency'      => 'USD',
                'is_active'     => true,
                'trial_days'    => 0,
                'sort_order'    => 0,
                'features'      => json_encode([
                    'monitored_apps_limit_5',
                    'basic_challenges',
                    'basic_locking',
                    'basic_dashboard',
                    'focus_timer',
                ]),
            ],
            [
                'slug'          => 'pro_monthly',
                'name'          => 'Pro — Monthly',
                'description'   => 'Full MindLock experience',
                'tier'          => 'pro',
                'billing_cycle' => 'monthly',
                'price'         => 4.99,
                'currency'      => 'USD',
                'store_product_id' => 'mindlock_pro_monthly',
                'is_active'     => true,
                'trial_days'    => 7,
                'sort_order'    => 1,
                'features'      => json_encode([
                    'unlimited_monitored_apps',
                    'advanced_challenges',
                    'strict_mode',
                    'recovery_mode',
                    'detailed_analytics',
                    'weekly_reports',
                    'mood_tracking',
                    'behavior_insights',
                    'adaptive_recommendations',
                ]),
            ],
            [
                'slug'          => 'pro_annual',
                'name'          => 'Pro — Annual',
                'description'   => 'Full MindLock — best value',
                'tier'          => 'pro',
                'billing_cycle' => 'annual',
                'price'         => 34.99,
                'currency'      => 'USD',
                'store_product_id' => 'mindlock_pro_annual',
                'is_active'     => true,
                'trial_days'    => 7,
                'sort_order'    => 2,
                'features'      => json_encode([
                    'unlimited_monitored_apps',
                    'advanced_challenges',
                    'strict_mode',
                    'recovery_mode',
                    'detailed_analytics',
                    'weekly_reports',
                    'mood_tracking',
                    'behavior_insights',
                    'adaptive_recommendations',
                    'priority_support',
                ]),
            ],
        ];

        foreach ($plans as $plan) {
            Plan::updateOrCreate(['slug' => $plan['slug']], $plan);
        }
    }
}
