<?php

namespace App\Enums;

enum ChallengeDifficultyEnum: string
{
    case Easy   = 'easy';
    case Medium = 'medium';
    case Hard   = 'hard';

    public function label(): string
    {
        return match($this) {
            self::Easy   => 'Easy',
            self::Medium => 'Medium',
            self::Hard   => 'Hard',
        };
    }

    public function rewardMultiplier(): float
    {
        return match($this) {
            self::Easy   => 1.0,
            self::Medium => 1.5,
            self::Hard   => 2.0,
        };
    }
}
