<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('courses', function (Blueprint $table) {
            $table->id();
            $table->foreignId('learning_path_id')->nullable()->constrained()->nullOnDelete();
            $table->string('title_ar');
            $table->string('slug')->unique();
            $table->text('description_ar')->nullable();
            $table->text('short_description_ar')->nullable();
            $table->string('cover_image')->nullable();
            $table->string('level')->default('beginner');
            $table->unsignedInteger('duration_minutes')->default(0);
            $table->unsignedInteger('lessons_count')->default(0);
            $table->unsignedInteger('order')->default(1);
            $table->boolean('is_featured')->default(false);
            $table->boolean('is_published')->default(false);
            $table->timestamp('published_at')->nullable();
            $table->timestamps();

            $table->index('learning_path_id');
            $table->index('level');
            $table->index('order');
            $table->index('is_featured');
            $table->index('is_published');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('courses');
    }
};