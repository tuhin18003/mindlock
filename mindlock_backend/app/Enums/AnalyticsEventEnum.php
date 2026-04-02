<?php

namespace App\Enums;

enum AnalyticsEventEnum: string
{
    // Auth
    case UserRegistered   = 'user_registered';
    case UserLoggedIn     = 'user_logged_in';
    case UserLoggedOut    = 'user_logged_out';

    // App locking
    case AppLocked        = 'app_locked';
    case AppUnlocked      = 'app_unlocked';
    case EmergencyUnlock  = 'emergency_unlock';

    // Challenges
    case ChallengeStarted   = 'challenge_started';
    case ChallengeCompleted = 'challenge_completed';
    case ChallengeFailed    = 'challenge_failed';
    case ChallengeSkipped   = 'challenge_skipped';

    // Focus
    case FocusSessionStarted   = 'focus_session_started';
    case FocusSessionCompleted = 'focus_session_completed';
    case FocusSessionAborted   = 'focus_session_aborted';

    // Subscription
    case PaywallViewed       = 'paywall_viewed';
    case SubscriptionStarted = 'subscription_started';
    case SubscriptionCancelled = 'subscription_cancelled';
    case TrialStarted        = 'trial_started';

    // Onboarding
    case OnboardingStarted   = 'onboarding_started';
    case OnboardingCompleted = 'onboarding_completed';
    case OnboardingSkipped   = 'onboarding_skipped';

    // Settings
    case AppAdded            = 'app_added';
    case AppRemoved          = 'app_removed';
    case LimitSet            = 'limit_set';
    case GoalUpdated         = 'goal_updated';
    case NotificationOptIn   = 'notification_opt_in';
    case NotificationOptOut  = 'notification_opt_out';
}
