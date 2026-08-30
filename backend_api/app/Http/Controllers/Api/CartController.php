<?php

namespace App\Http\Controllers\Api;

use App\Models\CartItem;
use App\Models\LibraryItem;
use Illuminate\Http\Request;

class CartController extends Controller
{
    public function index(Request $request)
    {
        $items = CartItem::query()
            ->where('user_id', $request->user()->id)
            ->with('libraryItem')
            ->latest()
            ->get();

        $total = $items->sum(function (CartItem $cartItem) {
            return $cartItem->quantity * $cartItem->price;
        });

        return $this->successResponse([
            'items' => $items,
            'total' => $total,
        ], 'تم جلب السلة بنجاح');
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'library_item_id' => ['required', 'exists:library_items,id'],
            'quantity' => ['nullable', 'integer', 'min:1'],
        ]);

        $libraryItem = LibraryItem::where('is_published', true)
            ->findOrFail($validated['library_item_id']);

        $cartItem = CartItem::updateOrCreate(
            [
                'user_id' => $request->user()->id,
                'library_item_id' => $libraryItem->id,
            ],
            [
                'quantity' => $validated['quantity'] ?? 1,
                'price' => $libraryItem->price,
            ]
        );

        return $this->successResponse(
            $cartItem->load('libraryItem'),
            'تمت إضافة العنصر إلى السلة بنجاح',
            201
        );
    }

    public function destroy(Request $request, CartItem $cartItem)
    {
        if ($cartItem->user_id !== $request->user()->id) {
            return $this->errorResponse('لا تملك صلاحية حذف هذا العنصر', null, 403);
        }

        $cartItem->delete();

        return $this->successResponse(null, 'تم حذف العنصر من السلة بنجاح');
    }
}