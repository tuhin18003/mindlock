<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;
use Spatie\Permission\Traits\HasRoles;

class User extends Authenticatable
{
    use HasApiTokens, HasFactory, Notifiable, SoftDeletes, HasRoles;

    protected $fillable = [
        'name',
        'email',
        'password',
        'avatar',
        'timezone',
        'locale',
        'status',
        'last_active_at',
        'referral_code',
        'referred_by',
    ];

    protected $hidden = [
        'password',
        'remember_token',
    ];

    protected $casts = [
        'email_verified_at' => 'datetime',
        'last_active_at' => 'datetime',
        'password' => 'hashed',
    ];

    public function deviceSessions(): HasMany
    {
        return $this->hasMany(DeviceSession::class);
    }

    public function entitlements(): HasMany
    {
        return $this->hasMany(Entitlement::class);
    }

    public function activeEntitlement(): HasOne
    {
        return $this->hasOne(Entitlement::class)
            ->where('status', 'active')
            ->orderByDesc('created_at');
    }

    public function notificationPreferences(): HasOne
    {
        return $this->hasOne(NotificationPreference::class);
    }

    public function streak(): HasOne
    {
        return $this->hasOne(Streak::class);
    }

    public function behaviorProfile(): HasOne
    {
        return $this->hasOne(BehaviorProfile::class);
    }

    public function monitoredApps(): HasMany
    {
        return $this->hasMany(MonitoredApp::class);
    }

    public function appLimits(): HasMany
    {
        return $this->hasMany(AppLimit::class);
    }

    public function usageLogs(): HasMany
    {
        return $this->hasMany(UsageLog::class);
    }

    public function lockEvents(): HasMany
    {
        return $this->hasMany(LockEvent::class);
    }

    public function unlockEvents(): HasMany
    {
        return $this->hasMany(UnlockEvent::class);
    }

    public function challengeCompletions(): HasMany
    {
        return $this->hasMany(ChallengeCompletion::class);
    }

    public function focusSessions(): HasMany
    {
        return $this->hasMany(FocusSession::class);
    }

    public function emergencyUnlocks(): HasMany
    {
        return $this->hasMany(EmergencyUnlock::class);
    }

    public function moodLogs(): HasMany
    {
        return $this->hasMany(MoodLog::class);
    }

    public function analyticsEvents(): HasMany
    {
        return $this->hasMany(AnalyticsEvent::class);
    }

    public function dailySummaries(): HasMany
    {
        return $this->hasMany(AnalyticsDailySummary::class);
    }

    public function recoveryScores(): HasMany
    {
        return $this->hasMany(RecoveryScore::class);
    }

    public function isPro(): bool
    {
        return $this->activeEntitlement?->tier === 'pro';
    }

    public function isActive(): bool
    {
        return $this->status === 'active';
    }
}
