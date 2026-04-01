<?php

namespace App\Services;

use App\Models\FeatureFlag;
use App\Models\User;

/**
 * FeatureGateService — controls which features are accessible.
 *
 * Check features here, not inline in controllers.
 */
class FeatureGateService
{
    // Pro-only features
    public const PRO_FEATURES = [
        'advanced_challenges',
        'strict_mode',
        'recovery_mode',
        'analytics_detailed',
        'custom_limits',
        'weekly_reports',
        'mood_tracking',
        'behavior_insights',
        'adaptive_recommendations',
        'accountability_partner',
        'unlimited_monitored_apps',
        'custom_challenge_cooldown',
    ];

    // Free tier limits
    public const FREE_MONITORED_APPS_LIMIT = 5;
    public const FREE_CHALLENGES_PER_DAY = 3;

    public function __construct(
        private readonly EntitlementResolver $entitlementResolver,
    ) {}

    public function canAccess(User $user, string $feature): bool
    {
        // Check feature flag first
        $flag = FeatureFlag::where('key', $feature)->first();
        if ($flag && !$this->isFlagEnabled($flag, $user)) {
            return false;
        }

        // Check Pro requirement
        if (in_array($feature, self::PRO_FEATURES)) {
            return $this->entitlementResolver->isPro($user);
        }

        return true;
    }

    public function getGates(User $user): array
    {
        $isPro = $this->entitlementResolver->isPro($user);

        return [
            'is_pro'                    => $isPro,
            'advanced_challenges'       => $isPro,
            'strict_mode'               => $isPro,
            'recovery_mode'             => $isPro,
            'analytics_detailed'        => $isPro,
            'custom_limits'             => $isPro,
            'weekly_reports'            => $isPro,
            'mood_tracking'             => $isPro,
            'behavior_insights'         => $isPro,
            'adaptive_recommendations'  => $isPro,
            'unlimited_monitored_apps'  => $isPro,
            'monitored_apps_limit'      => $isPro ? null : self::FREE_MONITORED_APPS_LIMIT,
            'challenges_per_day_limit'  => $isPro ? null : self::FREE_CHALLENGES_PER_DAY,
        ];
    }

    private function isFlagEnabled(FeatureFlag $flag, User $user): bool
    {
        if (!$flag->is_enabled) return false;

        return match ($flag->rollout_type) {
            'everyone'   => true,
            'pro_only'   => $this->entitlementResolver->isPro($user),
            'percentage' => ($user->id % 100) < $flag->rollout_percentage,
            'user_list'  => in_array($user->id, $flag->user_ids ?? []),
            default      => false,
        };
    }
}
