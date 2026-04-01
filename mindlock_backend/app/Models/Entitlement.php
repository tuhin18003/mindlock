<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Entitlement extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'plan_id',
        'tier',
        'source',
        'status',
        'starts_at',
        'expires_at',
        'grace_period_until',
        'granted_by',
        'notes',
        'reference_id',
    ];

    protected $casts = [
        'starts_at' => 'datetime',
        'expires_at' => 'datetime',
        'grace_period_until' => 'datetime',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function plan(): BelongsTo
    {
        return $this->belongsTo(Plan::class);
    }

    public function grantedBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'granted_by');
    }

    public function histories(): HasMany
    {
        return $this->hasMany(EntitlementHistory::class);
    }

    public function isPro(): bool
    {
        return $this->tier === 'pro';
    }

    public function isActive(): bool
    {
        return $this->status === 'active';
    }

    public function isExpired(): bool
    {
        return $this->expires_at !== null && $this->expires_at->isPast();
    }

    public function isLifetime(): bool
    {
        return $this->source === 'lifetime' || $this->expires_at === null;
    }

    public function daysRemaining(): ?int
    {
        if ($this->expires_at === null) return null;
        return max(0, (int) now()->diffInDays($this->expires_at, false));
    }

    public function scopeActive($query)
    {
        return $query->where('status', 'active');
    }

    public function scopePro($query)
    {
        return $query->where('tier', 'pro');
    }
}
