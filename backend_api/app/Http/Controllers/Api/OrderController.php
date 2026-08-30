<?php

namespace App\Http\Controllers\Api;

use App\Models\Order;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class OrderController extends Controller
{
    public function index(Request $request)
    {
        $orders = Order::query()
            ->where('user_id', $request->user()->id)
            ->with('items.libraryItem')
            ->latest()
            ->paginate(20);

        return $this->successResponse($orders, 'تم جلب الطلبات بنجاح');
    }

    public function show(Request $request, Order $order)
    {
        if ($order->user_id !== $request->user()->id) {
            return $this->errorResponse('لا تملك صلاحية عرض هذا الطلب', null, 403);
        }

        return $this->successResponse(
            $order->load(['items.libraryItem', 'payments']),
            'تم جلب تفاصيل الطلب بنجاح'
        );
    }

    public function store(Request $request)
    {
        $cartItems = $request->user()
            ->cartItems()
            ->with('libraryItem')
            ->get();

        if ($cartItems->isEmpty()) {
            return $this->errorResponse('السلة فارغة', null, 422);
        }

        $order = DB::transaction(function () use ($request, $cartItems) {
            $subtotal = $cartItems->sum(function ($cartItem) {
                return $cartItem->price * $cartItem->quantity;
            });

            $discount = 0;
            $total = $subtotal - $discount;

            $order = Order::create([
                'user_id' => $request->user()->id,
                'order_number' => 'RWI-' . now()->format('Ymd') . '-' . Str::upper(Str::random(6)),
                'subtotal' => $subtotal,
                'discount' => $discount,
                'total' => $total,
                'status' => $total <= 0 ? 'paid' : 'pending',
            ]);

            foreach ($cartItems as $cartItem) {
                $order->items()->create([
                    'library_item_id' => $cartItem->library_item_id,
                    'title_ar' => $cartItem->libraryItem->title_ar,
                    'price' => $cartItem->price,
                    'quantity' => $cartItem->quantity,
                    'total' => $cartItem->price * $cartItem->quantity,
                ]);
            }

            $request->user()->cartItems()->delete();

            return $order;
        });

        return $this->successResponse(
            $order->load('items.libraryItem'),
            'تم إنشاء الطلب بنجاح',
            201
        );
    }
}