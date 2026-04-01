<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('device_sessions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('device_id')->index();
            $table->string('device_name')->nullable();
            $table->string('platform'); // android, ios
            $table->string('os_version')->nullable();
            $table->string('app_version')->nullable();
            $table->string('token_id')->nullable(); // Sanctum token id reference
            $table->string('fcm_token')->nullable();
            $table->string('timezone')->nullable();
            $table->timestamp('last_seen_at')->nullable();
            $table->boolean('is_active')->default(true);
            $table->timestamps();

            $table->unique(['user_id', 'device_id']);
            $table->index(['device_id', 'is_active']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('device_sessions');
    }
};
