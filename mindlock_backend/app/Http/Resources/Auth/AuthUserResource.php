<?php

namespace App\Http\Resources\Auth;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class AuthUserResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id'                  => $this->id,
            'name'                => $this->name,
            'email'               => $this->email,
            'email_verified_at'   => $this->email_verified_at?->toIso8601String(),
            'avatar'              => $this->avatar ? asset("storage/{$this->avatar}") : null,
            'timezone'            => $this->timezone,
            'locale'              => $this->locale,
            'status'              => $this->status,
            'last_active_at'      => $this->last_active_at?->toIso8601String(),
            'created_at'          => $this->created_at->toIso8601String(),
            'roles'               => $this->getRoleNames()->values(),
        ];
    }
}
