<?php

namespace App\Http\Controllers\Api;

use App\Models\Order;
use Illuminate\Http\Request;
use Illuminate\Support\Str;

class PaymentController extends Controller
{
    public function store(Request $request)
    {
        $validated = $request->validate([
            'order_id' => ['required', 'exists:orders,id'],
            'provider' => ['nullable', 'string', 'max:50'],
        ]);

        $order = Order::where('user_id', $request->user()->id)
            ->findOrFail($validated['order_id']);

        if ($order->status === 'paid') {
            return $this->successResponse([
                'order' => $order,
                'payment_url' => null,
            ], 'هذا الطلب مدفوع بالفعل');
        }

        $payment = $order->payments()->create([
            'user_id' => $request->user()->id,
            'provider' => $validated['provider'] ?? config('services.payment.provider', 'stripe'),
            'provider_reference' => 'PAY-' . Str::upper(Str::random(12)),
            'amount' => $order->total,
            'currency' => 'USD',
            'status' => 'pending',
            'payload' => [],
        ]);

        return $this->successResponse([
            'payment' => $payment,
            'payment_url' => null,
            'message' => 'سيتم ربط بوابة الدفع لاحقًا',
        ], 'تم إنشاء عملية الدفع بنجاح', 201);
    }

    public function callback(Request $request)
    {
        return $this->successResponse([
            'received' => true,
            'payload' => $request->all(),
        ], 'تم استقبال رد بوابة الدفع');
    }
}