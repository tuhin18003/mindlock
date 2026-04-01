<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // Monitored apps — apps the user has selected to track or lock
        Schema::create('monitored_apps', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('package_name'); // com.instagram.android
            $table->string('app_name');
            $table->string('category')->nullable(); // social, entertainment, games, productivity
            $table->boolean('is_tracked')->default(true);
            $table->boolean('is_locked')->default(false);
            $table->boolean('strict_mode')->default(false); // no emergency unlock allowed
            $table->timestamps();

            $table->unique(['user_id', 'package_name']);
            $table->index(['user_id', 'is_locked']);
        });

        // App usage limits
        Schema::create('app_limits', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('package_name');
            $table->integer('daily_limit_minutes'); // 0 = blocked all day
            $table->integer('weekday_limit_minutes')->nullable(); // override for weekdays
            $table->integer('weekend_limit_minutes')->nullable(); // override for weekends
            $table->boolean('is_active')->default(true);
            $table->timestamps();

            $table->unique(['user_id', 'package_name']);
            $table->index(['user_id', 'is_active']);
        });

        // Usage logs — synced from device
        Schema::create('usage_logs', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('device_id')->index();
            $table->string('package_name');
            $table->date('date');
            $table->integer('usage_seconds')->default(0);
            $table->integer('open_count')->default(0);
            $table->string('category')->nullable();
            $table->timestamp('synced_at')->nullable();
            $table->timestamps();

            $table->unique(['user_id', 'device_id', 'package_name', 'date']);
            $table->index(['user_id', 'date']);
            $table->index(['user_id', 'package_name', 'date']);
        });

        // Lock events — when the lock was triggered
        Schema::create('lock_events', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('device_id')->index();
            $table->string('package_name');
            $table->string('app_name')->nullable();
            $table->integer('usage_seconds_at_lock'); // usage when locked
            $table->integer('limit_seconds'); // the limit that was hit
            $table->boolean('strict_mode')->default(false);
            $table->string('trigger_reason')->nullable(); // limit_reached, manual
            $table->timestamp('locked_at');
            $table->string('local_event_id')->nullable(); // device-generated UUID
            $table->timestamps();

            $table->index(['user_id', 'locked_at']);
            $table->index(['user_id', 'package_name', 'locked_at']);
        });

        // Unlock events — how the user unlocked
        Schema::create('unlock_events', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->foreignId('lock_event_id')->nullable()->constrained()->nullOnDelete();
            $table->string('device_id')->index();
            $table->string('package_name');
            $table->string('method'); // challenge, reflection, focus_timer, delay, emergency, habit_task
            $table->integer('reward_minutes')->default(0);
            $table->boolean('was_emergency')->default(false);
            $table->boolean('relocked')->default(false); // did they get locked again soon?
            $table->integer('relock_minutes')->nullable(); // minutes until relock
            $table->string('local_event_id')->nullable();
            $table->timestamp('unlocked_at');
            $table->timestamps();

            $table->index(['user_id', 'unlocked_at']);
            $table->index(['user_id', 'method']);
        });

        // Focus sessions
        Schema::create('focus_sessions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('device_id')->index();
            $table->integer('planned_minutes');
            $table->integer('actual_minutes')->nullable();
            $table->enum('status', ['active', 'completed', 'abandoned'])->default('active');
            $table->string('label')->nullable(); // user-defined label
            $table->string('local_event_id')->nullable();
            $table->timestamp('started_at');
            $table->timestamp('ended_at')->nullable();
            $table->timestamps();

            $table->index(['user_id', 'started_at']);
        });

        // Emergency unlocks
        Schema::create('emergency_unlocks', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->foreignId('lock_event_id')->nullable()->constrained()->nullOnDelete();
            $table->string('device_id')->index();
            $table->string('package_name');
            $table->string('reason')->nullable(); // user-provided reason
            $table->timestamp('used_at');
            $table->string('local_event_id')->nullable();
            $table->timestamps();

            $table->index(['user_id', 'used_at']);
        });

        // Streaks
        Schema::create('streaks', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete()->unique();
            $table->integer('current_streak')->default(0);
            $table->integer('longest_streak')->default(0);
            $table->date('last_streak_date')->nullable();
            $table->date('streak_start_date')->nullable();
            $table->integer('total_streak_days')->default(0);
            $table->timestamps();
        });

        // Mood / intent logs
        Schema::create('mood_logs', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('package_name')->nullable();
            $table->string('mood'); // bored, stressed, lonely, procrastinating, habit, intentional_need
            $table->string('context')->nullable(); // pre_unlock, post_unlock, daily_checkin
            $table->string('local_event_id')->nullable();
            $table->timestamp('logged_at');
            $table->timestamps();

            $table->index(['user_id', 'logged_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('mood_logs');
        Schema::dropIfExists('streaks');
        Schema::dropIfExists('emergency_unlocks');
        Schema::dropIfExists('focus_sessions');
        Schema::dropIfExists('unlock_events');
        Schema::dropIfExists('lock_events');
        Schema::dropIfExists('usage_logs');
        Schema::dropIfExists('app_limits');
        Schema::dropIfExists('monitored_apps');
    }
};
