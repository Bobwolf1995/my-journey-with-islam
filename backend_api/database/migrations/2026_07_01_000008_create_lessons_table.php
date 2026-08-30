<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('lessons', function (Blueprint $table) {
            $table->id();
            $table->foreignId('course_id')->constrained()->cascadeOnDelete();
            $table->foreignId('course_section_id')->nullable()->constrained('course_sections')->nullOnDelete();
            $table->string('title_ar');
            $table->string('slug')->unique();
            $table->longText('content_ar')->nullable();
            $table->string('lesson_type')->default('text');
            $table->string('video_url')->nullable();
            $table->string('audio_url')->nullable();
            $table->string('file_url')->nullable();
            $table->unsignedInteger('duration_minutes')->default(0);
            $table->unsignedInteger('points')->default(0);
            $table->unsignedInteger('order')->default(1);
            $table->boolean('is_free')->default(true);
            $table->boolean('is_published')->default(false);
            $table->timestamps();

            $table->index(['course_id', 'order']);
            $table->index('course_section_id');
            $table->index('lesson_type');
            $table->index('is_published');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('lessons');
    }
};