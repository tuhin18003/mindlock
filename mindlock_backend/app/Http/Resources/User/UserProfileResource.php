<?php

namespace App\Http\Resources\User;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class UserProfileResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id'                   => $this->id,
            'name'                 => $this->name,
            'email'                => $this->email,
            'email_verified'       => !is_null($this->email_verified_at),
            'avatar'               => $this->avatar ? asset("storage/{$this->avatar}") : null,
            'timezone'             => $this->timezone,
            'locale'               => $this->locale,
            'status'               => $this->status,
            'created_at'           => $this->created_at->toIso8601String(),
            'last_active_at'       => $this->last_active_at?->toIso8601String(),
            'streak'               => $this->whenLoaded('streak', fn() => [
                'current'  => $this->streak?->current_streak ?? 0,
                'longest'  => $this->streak?->longest_streak ?? 0,
                'last_date'=> $this->streak?->last_streak_date,
            ]),
            'notification_preferences' => $this->whenLoaded('notificationPreferences', fn() => $this->notificationPreferences),
        ];
    }
}
