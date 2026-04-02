<?php

namespace App\Http\Resources\Admin;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class AdminUserResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id'              => $this->id,
            'name'            => $this->name,
            'email'           => $this->email,
            'avatar'          => $this->avatar ? asset("storage/{$this->avatar}") : null,
            'status'          => $this->status,
            'timezone'        => $this->timezone,
            'email_verified'  => !is_null($this->email_verified_at),
            'created_at'      => $this->created_at->toIso8601String(),
            'last_active_at'  => $this->last_active_at?->toIso8601String(),
            'entitlement'     => $this->whenLoaded('activeEntitlement', fn() => $this->activeEntitlement ? [
                'tier'        => $this->activeEntitlement->tier,
                'source'      => $this->activeEntitlement->source,
                'status'      => $this->activeEntitlement->status,
                'expires_at'  => $this->activeEntitlement->expires_at?->toIso8601String(),
                'is_lifetime' => $this->activeEntitlement->isLifetime(),
            ] : ['tier' => 'free']),
            'streak'          => $this->whenLoaded('streak', fn() => [
                'current' => $this->streak?->current_streak ?? 0,
                'longest' => $this->streak?->longest_streak ?? 0,
            ]),
        ];
    }
}
