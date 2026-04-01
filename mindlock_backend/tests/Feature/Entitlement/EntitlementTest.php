<?php

use App\Models\User;
use App\Services\EntitlementResolver;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(RefreshDatabase::class);

test('resolver returns free tier when no entitlement exists', function () {
    $user = User::factory()->create();
    $resolver = app(EntitlementResolver::class);

    expect($resolver->isPro($user))->toBeFalse();
});

test('admin can grant pro access', function () {
    $user = User::factory()->create();
    $resolver = app(EntitlementResolver::class);

    $entitlement = $resolver->grant(
        user: $user,
        source: 'admin_grant',
        expiresAt: now()->addDays(30),
    );

    expect($resolver->isPro($user))->toBeTrue();
    expect($entitlement->tier)->toBe('pro');
    expect($entitlement->source)->toBe('admin_grant');
});

test('lifetime pro never expires', function () {
    $user = User::factory()->create();
    $resolver = app(EntitlementResolver::class);

    $entitlement = $resolver->grantLifetime($user);

    expect($entitlement->expires_at)->toBeNull();
    expect($entitlement->isLifetime())->toBeTrue();
    expect($resolver->isPro($user))->toBeTrue();
});

test('revoke removes pro access', function () {
    $user = User::factory()->create();
    $resolver = app(EntitlementResolver::class);

    $resolver->grant($user, 'admin_grant');
    expect($resolver->isPro($user))->toBeTrue();

    $resolver->revoke($user);
    expect($resolver->isPro($user))->toBeFalse();
});

test('summary returns correct structure', function () {
    $user = User::factory()->create();
    $resolver = app(EntitlementResolver::class);

    $resolver->grant($user, 'admin_grant', expiresAt: now()->addDays(7));

    $summary = $resolver->getSummary($user);

    expect($summary)->toHaveKeys(['tier', 'is_pro', 'source', 'status', 'expires_at', 'days_remaining']);
    expect($summary['is_pro'])->toBeTrue();
    expect($summary['days_remaining'])->toBeBetween(6, 7);
});

test('entitlement history is recorded on grant', function () {
    $user = User::factory()->create();
    $resolver = app(EntitlementResolver::class);

    $entitlement = $resolver->grant($user, 'admin_grant');

    expect($entitlement->histories()->count())->toBe(1);
    expect($entitlement->histories()->first()->event)->toBe('activated');
});
