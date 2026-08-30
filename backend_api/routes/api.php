<?php

use App\Http\Controllers\Api\AiAssistantController;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\BadgeController;
use App\Http\Controllers\Api\CartController;
use App\Http\Controllers\Api\CommunityController;
use App\Http\Controllers\Api\CourseController;
use App\Http\Controllers\Api\FavoriteController;
use App\Http\Controllers\Api\HomeController;
use App\Http\Controllers\Api\JourneyController;
use App\Http\Controllers\Api\LessonController;
use App\Http\Controllers\Api\LibraryController;
use App\Http\Controllers\Api\MentorController;
use App\Http\Controllers\Api\MessageController;
use App\Http\Controllers\Api\NotificationController;
use App\Http\Controllers\Api\OrderController;
use App\Http\Controllers\Api\PaymentController;
use App\Http\Controllers\Api\ProfileController;
use App\Http\Controllers\Api\TaskController;
use Illuminate\Support\Facades\Route;

Route::prefix('auth')->group(function () {
    Route::post('/register', [AuthController::class, 'register']);
    Route::post('/login', [AuthController::class, 'login']);
    Route::post('/forgot-password', [AuthController::class, 'forgotPassword']);
    Route::post('/reset-password', [AuthController::class, 'resetPassword']);

    Route::middleware('auth:sanctum')->group(function () {
        Route::get('/me', [AuthController::class, 'me']);
        Route::post('/logout', [AuthController::class, 'logout']);
    });
});

Route::middleware('auth:sanctum')->group(function () {
    Route::get('/home', [HomeController::class, 'index']);

    Route::get('/journey', [JourneyController::class, 'index']);

    Route::get('/learning-paths', [CourseController::class, 'learningPaths']);
    Route::get('/learning-paths/{learningPath}', [CourseController::class, 'showLearningPath']);

    Route::get('/courses', [CourseController::class, 'index']);
    Route::get('/courses/{course}', [CourseController::class, 'show']);
    Route::post('/courses/{course}/enroll', [CourseController::class, 'enroll']);
    Route::get('/courses/{course}/progress', [CourseController::class, 'progress']);

    Route::get('/lessons/{lesson}', [LessonController::class, 'show']);
    Route::post('/lessons/{lesson}/complete', [LessonController::class, 'complete']);
    Route::post('/lessons/{lesson}/quiz/submit', [LessonController::class, 'submitQuiz']);

    Route::get('/favorites', [FavoriteController::class, 'index']);
    Route::post('/favorites', [FavoriteController::class, 'store']);
    Route::delete('/favorites', [FavoriteController::class, 'destroy']);
    Route::post('/favorites/toggle', [FavoriteController::class, 'toggle']);

    Route::get('/tasks', [TaskController::class, 'index']);
    Route::post('/tasks/{task}/complete', [TaskController::class, 'complete']);

    Route::get('/mentor', [MentorController::class, 'myMentor']);
    Route::get('/mentor/students', [MentorController::class, 'students']);
    Route::get('/mentor/students/{student}/progress', [MentorController::class, 'studentProgress']);
    Route::post('/mentor/students/{student}/notes', [MentorController::class, 'storeNote']);

    Route::get('/conversations', [MessageController::class, 'conversations']);
    Route::post('/conversations', [MessageController::class, 'createConversation']);
    Route::get('/conversations/{conversation}/messages', [MessageController::class, 'messages']);
    Route::post('/conversations/{conversation}/messages', [MessageController::class, 'sendMessage']);

    Route::get('/library/categories', [LibraryController::class, 'categories']);
    Route::get('/library/items', [LibraryController::class, 'items']);
    Route::get('/library/items/{libraryItem}', [LibraryController::class, 'show']);

    Route::get('/cart', [CartController::class, 'index']);
    Route::post('/cart/items', [CartController::class, 'store']);
    Route::delete('/cart/items/{cartItem}', [CartController::class, 'destroy']);

    Route::get('/orders', [OrderController::class, 'index']);
    Route::post('/orders', [OrderController::class, 'store']);
    Route::get('/orders/{order}', [OrderController::class, 'show']);

    Route::post('/payments', [PaymentController::class, 'store']);

    Route::get('/badges/my', [BadgeController::class, 'myBadges']);
    Route::get('/levels', [BadgeController::class, 'levels']);

    Route::get('/community/groups', [CommunityController::class, 'groups']);
    Route::get('/community/posts', [CommunityController::class, 'posts']);
    Route::post('/community/posts', [CommunityController::class, 'storePost']);
    Route::post('/community/posts/{post}/comments', [CommunityController::class, 'storeComment']);
    Route::post('/community/posts/{post}/like', [CommunityController::class, 'toggleLike']);

    Route::get('/notifications', [NotificationController::class, 'index']);
    Route::post('/notifications/{notification}/read', [NotificationController::class, 'markAsRead']);

    Route::get('/profile/stats', [ProfileController::class, 'stats']);
    Route::get('/profile', [ProfileController::class, 'show']);
    Route::put('/profile', [ProfileController::class, 'update']);

    Route::post('/ai/ask', [AiAssistantController::class, 'ask']);
});

Route::post('/payments/callback', [PaymentController::class, 'callback']);