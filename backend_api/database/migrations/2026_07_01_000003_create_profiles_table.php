<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('profiles', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->unique()->constrained()->cascadeOnDelete();
            $table->foreignId('current_level_id')->nullable()->constrained('levels')->nullOnDelete();
            $table->string('display_name')->nullable();
            $table->string('avatar')->nullable();
            $table->text('bio')->nullable();
            $table->string('country')->nullable();
            $table->string('city')->nullable();
            $table->string('language')->default('ar');
            $table->unsignedInteger('points')->default(0);
            $table->unsignedInteger('streak_days')->default(0);
            $table->date('last_activity_date')->nullable();
            $table->json('preferences')->nullable();
            $table->timestamps();

            $table->index('current_level_id');
            $table->index('points');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('profiles');
    }
};