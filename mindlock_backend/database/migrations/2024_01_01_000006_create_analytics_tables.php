<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // Raw analytics events (ingested from app)
        Schema::create('analytics_events', function (Blueprint $table) {
            $table->id();
            $table->string('event_name')->index();
            $table->unsignedBigInteger('user_id')->nullable()->index();
            $table->string('anonymous_id')->nullable()->index();
            $table->string('session_id')->nullable();
            $table->string('device_id')->nullable();
            $table->string('platform')->nullable(); // android, ios
            $table->string('app_version')->nullable();
            $table->string('timezone')->nullable();
            $table->enum('entitlement_tier', ['free', 'pro'])->nullable();
            $table->json('properties')->nullable();
            $table->timestamp('occurred_at')->index();
            $table->timestamps();

            $table->index(['event_name', 'occurred_at']);
            $table->index(['user_id', 'event_name', 'occurred_at']);
        });

        // Daily aggregated summaries per user
        Schema::create('analytics_daily_summaries', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->date('date');
            $table->integer('total_screen_time_seconds')->default(0);
            $table->integer('recovered_time_seconds')->default(0);
            $table->integer('blocked_time_seconds')->default(0);
            $table->integer('focus_time_seconds')->default(0);
            $table->integer('lock_triggers')->default(0);
            $table->integer('unlock_attempts')->default(0);
            $table->integer('challenge_completions')->default(0);
            $table->integer('emergency_unlocks')->default(0);
            $table->integer('relock_events')->default(0);
            $table->integer('apps_opened')->default(0);
            $table->integer('recovery_score')->default(0);
            $table->boolean('streak_maintained')->default(false);
            $table->timestamps();

            $table->unique(['user_id', 'date']);
            $table->index(['user_id', 'date']);
        });

        // App-level aggregations per day
        Schema::create('analytics_app_summaries', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('package_name');
            $table->string('category')->nullable();
            $table->date('date');
            $table->integer('usage_seconds')->default(0);
            $table->integer('lock_count')->default(0);
            $table->integer('unlock_count')->default(0);
            $table->integer('emergency_unlock_count')->default(0);
            $table->timestamps();

            $table->unique(['user_id', 'package_name', 'date']);
            $table->index(['user_id', 'date']);
            $table->index(['user_id', 'package_name']);
        });

        // Behavior profiles — aggregated user patterns
        Schema::create('behavior_profiles', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete()->unique();
            $table->string('top_distraction_app')->nullable();
            $table->string('peak_usage_hour')->nullable(); // "21" = 9pm
            $table->string('preferred_challenge_type')->nullable();
            $table->decimal('avg_daily_screen_time_minutes', 8, 2)->nullable();
            $table->decimal('avg_daily_recovered_minutes', 8, 2)->nullable();
            $table->decimal('challenge_success_rate', 5, 2)->nullable(); // 0-100
            $table->decimal('emergency_unlock_rate', 5, 2)->nullable(); // 0-100
            $table->decimal('relock_rate', 5, 2)->nullable();
            $table->integer('last_30_day_score_avg')->nullable();
            $table->enum('risk_level', ['low', 'medium', 'high'])->nullable();
            $table->timestamp('last_computed_at')->nullable();
            $table->timestamps();
        });

        // Feature flags
        Schema::create('feature_flags', function (Blueprint $table) {
            $table->id();
            $table->string('key')->unique();
            $table->string('name');
            $table->text('description')->nullable();
            $table->boolean('is_enabled')->default(false);
            $table->enum('rollout_type', ['everyone', 'pro_only', 'percentage', 'user_list'])->default('everyone');
            $table->integer('rollout_percentage')->default(100);
            $table->json('user_ids')->nullable(); // specific user ids for user_list rollout
            $table->timestamps();
        });

        // Admin audit logs
        Schema::create('admin_audit_logs', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('admin_id')->index();
            $table->string('action'); // grant_pro, revoke_pro, suspend_user, etc.
            $table->string('target_type')->nullable(); // user, entitlement, challenge
            $table->unsignedBigInteger('target_id')->nullable();
            $table->json('before_state')->nullable();
            $table->json('after_state')->nullable();
            $table->string('notes')->nullable();
            $table->string('ip_address')->nullable();
            $table->timestamps();

            $table->index(['admin_id', 'created_at']);
            $table->index(['target_type', 'target_id']);
        });

        // Support tickets (placeholder)
        Schema::create('support_tickets', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('subject');
            $table->text('body');
            $table->enum('status', ['open', 'in_progress', 'resolved', 'closed'])->default('open');
            $table->enum('priority', ['low', 'medium', 'high', 'urgent'])->default('medium');
            $table->unsignedBigInteger('assigned_to')->nullable(); // admin user
            $table->text('admin_notes')->nullable();
            $table->timestamp('resolved_at')->nullable();
            $table->timestamps();

            $table->index(['status', 'priority']);
            $table->index('user_id');
        });

        // Notification preferences
        Schema::create('notification_preferences', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete()->unique();
            $table->boolean('daily_summary')->default(true);
            $table->boolean('streak_reminders')->default(true);
            $table->boolean('weekly_report')->default(true);
            $table->boolean('lock_triggered')->default(false);
            $table->boolean('challenge_reminders')->default(true);
            $table->boolean('pro_expiry_reminder')->default(true);
            $table->string('quiet_hours_start')->nullable(); // "22:00"
            $table->string('quiet_hours_end')->nullable(); // "07:00"
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('notification_preferences');
        Schema::dropIfExists('support_tickets');
        Schema::dropIfExists('admin_audit_logs');
        Schema::dropIfExists('feature_flags');
        Schema::dropIfExists('behavior_profiles');
        Schema::dropIfExists('analytics_app_summaries');
        Schema::dropIfExists('analytics_daily_summaries');
        Schema::dropIfExists('analytics_events');
    }
};
