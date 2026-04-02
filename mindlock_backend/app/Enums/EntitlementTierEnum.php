<?php

namespace App\Enums;

enum EntitlementTierEnum: string
{
    case Free = 'free';
    case Pro  = 'pro';

    public function isPro(): bool
    {
        return $this === self::Pro;
    }

    public function label(): string
    {
        return match($this) {
            self::Free => 'Free',
            self::Pro  => 'Pro',
        };
    }
}
