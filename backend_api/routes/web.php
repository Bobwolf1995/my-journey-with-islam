<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return response()->json([
        'success' => true,
        'message' => 'Rihlati With Islam API is running.',
        'data' => [
            'app' => config('app.name'),
            'version' => '1.0.0',
            'admin_url' => url('/admin'),
            'api_url' => url('/api'),
        ],
    ]);
});

Route::get('/reset-password/{token}', function (Request $request, string $token) {
    return response()->json([
        'success' => true,
        'message' => 'رابط استعادة كلمة المرور صالح للاستخدام داخل التطبيق.',
        'data' => [
            'token' => $token,
            'email' => $request->query('email'),
        ],
    ]);
})->name('password.reset');