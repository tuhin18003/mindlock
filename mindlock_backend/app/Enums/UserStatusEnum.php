<?php

namespace App\Enums;

enum UserStatusEnum: string
{
    case Active    = 'active';
    case Suspended = 'suspended';
    case Deleted   = 'deleted';

    public function label(): string
    {
        return match($this) {
            self::Active    => 'Active',
            self::Suspended => 'Suspended',
            self::Deleted   => 'Deleted',
        };
    }

    public function canLogin(): bool
    {
        return $this === self::Active;
    }
}
