<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // Plans catalog
        Schema::create('plans', function (Blueprint $table) {
            $table->id();
            $table->string('slug')->unique(); // 'free', 'pro_monthly', 'pro_annual', 'pro_lifetime'
            $table->string('name');
            $table->text('description')->nullable();
            $table->enum('tier', ['free', 'pro'])->default('free');
            $table->enum('billing_cycle', ['once', 'monthly', 'annual', 'none'])->default('none');
            $table->decimal('price', 10, 2)->default(0.00);
            $table->string('currency', 3)->default('USD');
            $table->string('store_product_id')->nullable(); // Google/Apple SKU
            $table->boolean('is_active')->default(true);
            $table->integer('trial_days')->default(0);
            $table->json('features')->nullable(); // list of feature keys included
            $table->integer('sort_order')->default(0);
            $table->timestamps();

            $table->index(['tier', 'is_active']);
        });

        // Entitlements — the authoritative source of Pro access
        Schema::create('entitlements', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->foreignId('plan_id')->nullable()->constrained()->nullOnDelete();
            $table->enum('tier', ['free', 'pro'])->default('free');
            $table->enum('source', [
                'admin_grant',
                'trial',
                'purchase',
                'subscription',
                'coupon',
                'lifetime',
                'referral',
            ])->default('admin_grant');
            $table->enum('status', ['active', 'expired', 'revoked', 'grace_period'])->default('active');
            $table->timestamp('starts_at')->nullable();
            $table->timestamp('expires_at')->nullable(); // null = lifetime
            $table->timestamp('grace_period_until')->nullable();
            $table->unsignedBigInteger('granted_by')->nullable()->index(); // admin user id
            $table->text('notes')->nullable(); // admin notes
            $table->string('reference_id')->nullable(); // subscription/purchase ID
            $table->timestamps();

            $table->index(['user_id', 'status']);
            $table->index(['user_id', 'tier', 'status']);
            $table->index('expires_at');
        });

        // Entitlement audit history
        Schema::create('entitlement_histories', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->foreignId('entitlement_id')->constrained()->cascadeOnDelete();
            $table->string('event'); // activated, expired, revoked, renewed, upgraded, downgraded
            $table->enum('from_tier', ['free', 'pro'])->nullable();
            $table->enum('to_tier', ['free', 'pro'])->nullable();
            $table->enum('source', ['admin_grant', 'trial', 'purchase', 'subscription', 'coupon', 'lifetime', 'referral', 'system'])->nullable();
            $table->unsignedBigInteger('performed_by')->nullable(); // user or admin
            $table->text('notes')->nullable();
            $table->json('metadata')->nullable();
            $table->timestamp('occurred_at');
            $table->timestamps();

            $table->index(['user_id', 'occurred_at']);
            $table->index('entitlement_id');
        });

        // Purchases (billing transactions)
        Schema::create('purchases', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->foreignId('plan_id')->nullable()->constrained()->nullOnDelete();
            $table->string('store'); // google_play, apple, stripe
            $table->string('transaction_id')->unique();
            $table->string('product_id')->nullable(); // store product SKU
            $table->decimal('amount', 10, 2);
            $table->string('currency', 3)->default('USD');
            $table->enum('status', ['pending', 'completed', 'refunded', 'failed'])->default('completed');
            $table->timestamp('purchased_at');
            $table->timestamp('expires_at')->nullable();
            $table->json('raw_response')->nullable();
            $table->timestamps();

            $table->index(['user_id', 'status']);
            $table->index('transaction_id');
        });

        // Subscriptions
        Schema::create('subscriptions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->foreignId('plan_id')->nullable()->constrained()->nullOnDelete();
            $table->string('store'); // google_play, apple, stripe
            $table->string('store_subscription_id')->unique();
            $table->enum('status', ['active', 'cancelled', 'expired', 'paused', 'trial'])->default('active');
            $table->timestamp('trial_ends_at')->nullable();
            $table->timestamp('current_period_start')->nullable();
            $table->timestamp('current_period_end')->nullable();
            $table->timestamp('cancelled_at')->nullable();
            $table->boolean('auto_renew')->default(true);
            $table->json('raw_data')->nullable();
            $table->timestamps();

            $table->index(['user_id', 'status']);
        });

        // Coupons
        Schema::create('coupons', function (Blueprint $table) {
            $table->id();
            $table->string('code')->unique();
            $table->string('description')->nullable();
            $table->enum('type', ['trial_days', 'pro_months', 'pro_lifetime', 'discount_percent'])->default('trial_days');
            $table->integer('value'); // days, months, or percentage
            $table->integer('max_uses')->default(1);
            $table->integer('used_count')->default(0);
            $table->boolean('is_active')->default(true);
            $table->timestamp('expires_at')->nullable();
            $table->timestamps();

            $table->index(['code', 'is_active']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('coupons');
        Schema::dropIfExists('subscriptions');
        Schema::dropIfExists('purchases');
        Schema::dropIfExists('entitlement_histories');
        Schema::dropIfExists('entitlements');
        Schema::dropIfExists('plans');
    }
};
