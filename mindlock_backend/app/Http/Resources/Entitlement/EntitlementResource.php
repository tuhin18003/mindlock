<?php

namespace App\Http\Resources\Entitlement;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class EntitlementResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id'              => $this->id,
            'tier'            => $this->tier,
            'is_pro'          => $this->tier === 'pro',
            'source'          => $this->source,
            'status'          => $this->status,
            'starts_at'       => $this->starts_at?->toIso8601String(),
            'expires_at'      => $this->expires_at?->toIso8601String(),
            'is_lifetime'     => $this->isLifetime(),
            'days_remaining'  => $this->daysRemaining(),
            'plan'            => $this->whenLoaded('plan', fn() => [
                'id'   => $this->plan?->id,
                'slug' => $this->plan?->slug,
                'name' => $this->plan?->name,
            ]),
        ];
    }
}
