<?php

namespace App\Enums;

enum EntitlementSourceEnum: string
{
    case AdminGrant    = 'admin_grant';
    case Lifetime      = 'lifetime';
    case Trial         = 'trial';
    case Coupon        = 'coupon';
    case Subscription  = 'subscription';
    case PlayStore     = 'play_store';
    case AppStore      = 'app_store';

    public function label(): string
    {
        return match($this) {
            self::AdminGrant   => 'Admin Grant',
            self::Lifetime     => 'Lifetime Purchase',
            self::Trial        => 'Free Trial',
            self::Coupon       => 'Coupon Code',
            self::Subscription => 'Subscription',
            self::PlayStore    => 'Google Play',
            self::AppStore     => 'App Store',
        };
    }

    public function isManual(): bool
    {
        return in_array($this, [self::AdminGrant, self::Lifetime, self::Trial, self::Coupon]);
    }
}
