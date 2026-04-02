<?php

namespace App\Enums;

enum ChallengeTypeEnum: string
{
    case Reflection  = 'reflection';
    case Breathing   = 'breathing';
    case Quiz        = 'quiz';
    case Physical    = 'physical';
    case Mindfulness = 'mindfulness';
    case Custom      = 'custom';

    public function label(): string
    {
        return match($this) {
            self::Reflection  => 'Reflection',
            self::Breathing   => 'Breathing Exercise',
            self::Quiz        => 'Quiz',
            self::Physical    => 'Physical Activity',
            self::Mindfulness => 'Mindfulness',
            self::Custom      => 'Custom',
        };
    }

    public function isFreeType(): bool
    {
        return in_array($this, [self::Reflection, self::Breathing]);
    }
}
