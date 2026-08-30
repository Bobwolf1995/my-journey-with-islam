<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('library_categories', function (Blueprint $table) {
            $table->id();
            $table->string('name_ar');
            $table->string('slug')->unique();
            $table->text('description_ar')->nullable();
            $table->string('icon')->nullable();
            $table->string('color')->nullable();
            $table->unsignedInteger('order')->default(1);
            $table->boolean('is_active')->default(true);
            $table->timestamps();

            $table->index('order');
            $table->index('is_active');
        });

        Schema::create('library_items', function (Blueprint $table) {
            $table->id();
            $table->foreignId('library_category_id')->nullable()->constrained()->nullOnDelete();
            $table->string('title_ar');
            $table->string('slug')->unique();
            $table->text('description_ar')->nullable();
            $table->longText('content_ar')->nullable();
            $table->string('type')->default('book');
            $table->string('cover_image')->nullable();
            $table->string('file_url')->nullable();
            $table->decimal('price', 10, 2)->default(0);
            $table->boolean('is_free')->default(true);
            $table->boolean('is_featured')->default(false);
            $table->boolean('is_published')->default(false);
            $table->timestamp('published_at')->nullable();
            $table->timestamps();

            $table->index('library_category_id');
            $table->index('type');
            $table->index('is_free');
            $table->index('is_featured');
            $table->index('is_published');
        });

        Schema::create('cart_items', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->foreignId('library_item_id')->constrained()->cascadeOnDelete();
            $table->unsignedInteger('quantity')->default(1);
            $table->timestamps();

            $table->unique(['user_id', 'library_item_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('cart_items');
        Schema::dropIfExists('library_items');
        Schema::dropIfExists('library_categories');
    }
};