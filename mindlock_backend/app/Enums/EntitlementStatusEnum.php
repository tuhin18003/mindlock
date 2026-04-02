<?php

namespace App\Enums;

enum EntitlementStatusEnum: string
{
    case Active   = 'active';
    case Expired  = 'expired';
    case Revoked  = 'revoked';
    case Pending  = 'pending';

    public function label(): string
    {
        return match($this) {
            self::Active  => 'Active',
            self::Expired => 'Expired',
            self::Revoked => 'Revoked',
            self::Pending => 'Pending',
        };
    }

    public function isUsable(): bool
    {
        return $this === self::Active;
    }
}
