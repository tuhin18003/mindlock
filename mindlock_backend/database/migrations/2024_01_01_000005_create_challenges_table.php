<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('challenge_categories', function (Blueprint $table) {
            $table->id();
            $table->string('slug')->unique();
            $table->string('name');
            $table->string('description')->nullable();
            $table->string('icon')->nullable();
            $table->string('color')->nullable();
            $table->boolean('is_active')->default(true);
            $table->integer('sort_order')->default(0);
            $table->timestamps();
        });

        Schema::create('challenges', function (Blueprint $table) {
            $table->id();
            $table->foreignId('category_id')->constrained('challenge_categories')->cascadeOnDelete();
            $table->string('slug')->unique();
            $table->string('title');
            $table->text('description');
            $table->string('type'); // learning_task, reflection, mini_challenge, focus_timer, habit_task, delay_timer
            $table->string('content')->nullable(); // question text, task description
            $table->enum('difficulty', ['easy', 'medium', 'hard'])->default('easy');
            $table->integer('reward_minutes')->default(5);
            $table->integer('estimated_seconds')->default(60); // how long to complete
            $table->boolean('is_pro')->default(false); // Pro-only challenge
            $table->boolean('is_active')->default(true);
            $table->string('goal')->nullable(); // intervention goal: awareness, reflection, commitment
            $table->integer('cooldown_minutes')->default(0); // cooldown before repeating
            $table->decimal('effectiveness_score', 4, 2)->nullable(); // admin-tracked
            $table->integer('completion_count')->default(0);
            $table->integer('skip_count')->default(0);
            $table->integer('sort_order')->default(0);
            $table->timestamps();

            $table->index(['type', 'is_active']);
            $table->index(['is_pro', 'is_active']);
        });

        Schema::create('challenge_completions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->foreignId('challenge_id')->constrained()->cascadeOnDelete();
            $table->foreignId('lock_event_id')->nullable()->constrained()->nullOnDelete();
            $table->string('device_id')->index();
            $table->string('package_name')->nullable(); // which app triggered this
            $table->enum('result', ['completed', 'skipped', 'failed'])->default('completed');
            $table->integer('time_seconds')->nullable(); // how long completion took
            $table->integer('reward_granted_minutes')->default(0);
            $table->string('user_response')->nullable(); // for reflection prompts
            $table->string('local_event_id')->nullable();
            $table->timestamp('completed_at');
            $table->timestamps();

            $table->index(['user_id', 'completed_at']);
            $table->index(['user_id', 'challenge_id']);
            $table->index('challenge_id');
        });

        Schema::create('recovery_scores', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->date('date');
            $table->integer('score')->default(0); // 0-100
            $table->integer('recovered_minutes')->default(0);
            $table->integer('challenge_completions')->default(0);
            $table->integer('emergency_unlocks')->default(0);
            $table->integer('relock_count')->default(0);
            $table->decimal('discipline_ratio', 5, 2)->nullable();
            $table->timestamps();

            $table->unique(['user_id', 'date']);
            $table->index(['user_id', 'date']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('recovery_scores');
        Schema::dropIfExists('challenge_completions');
        Schema::dropIfExists('challenges');
        Schema::dropIfExists('challenge_categories');
    }
};
