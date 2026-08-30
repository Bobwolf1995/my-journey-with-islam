<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('quiz_options', function (Blueprint $table) {
            $table->id();
            $table->foreignId('quiz_question_id')->constrained('quiz_questions')->cascadeOnDelete();
            $table->text('option_ar');
            $table->boolean('is_correct')->default(false);
            $table->unsignedInteger('order')->default(1);
            $table->timestamps();

            $table->index('quiz_question_id');
            $table->index(['quiz_question_id', 'order']);
            $table->index('is_correct');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('quiz_options');
    }
};
