<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('mentors', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->unique()->constrained()->cascadeOnDelete();
            $table->string('specialization')->nullable();
            $table->text('bio')->nullable();
            $table->boolean('is_available')->default(true);
            $table->decimal('rating', 3, 2)->nullable();
            $table->timestamps();

            $table->index(['is_available', 'rating']);
        });

        Schema::create('mentor_students', function (Blueprint $table) {
            $table->id();
            $table->foreignId('mentor_id')->constrained()->cascadeOnDelete();
            $table->foreignId('student_id')->constrained('users')->cascadeOnDelete();
            $table->enum('status', ['active', 'paused', 'ended'])->default('active');
            $table->timestamp('assigned_at')->nullable();
            $table->timestamps();

            $table->unique(['mentor_id', 'student_id']);
            $table->index(['student_id', 'status']);
        });

        Schema::create('mentor_notes', function (Blueprint $table) {
            $table->id();
            $table->foreignId('mentor_id')->constrained()->cascadeOnDelete();
            $table->foreignId('student_id')->constrained('users')->cascadeOnDelete();
            $table->text('note');
            $table->timestamps();

            $table->index(['mentor_id', 'student_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('mentor_notes');
        Schema::dropIfExists('mentor_students');
        Schema::dropIfExists('mentors');
    }
};