<?php

namespace App\Http\Controllers\Api;

use App\Models\Favorite;
use App\Models\LibraryCategory;
use App\Models\LibraryItem;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class LibraryController extends Controller
{
    public function categories()
    {
        $categories = LibraryCategory::query()
            ->where('is_active', true)
            ->orderBy('order')
            ->get();

        return $this->successResponse($categories, 'تم جلب تصنيفات المكتبة بنجاح');
    }

    public function items(Request $request)
    {
        $userId = $request->user()->id;

        $items = LibraryItem::query()
            ->with('category')
            ->where('is_published', true)
            ->when($request->filled('category_id'), function ($query) use ($request) {
                $query->where('library_category_id', $request->integer('category_id'));
            })
            ->when($request->filled('library_category_id'), function ($query) use ($request) {
                $query->where('library_category_id', $request->integer('library_category_id'));
            })
            ->when($request->filled('category_slug'), function ($query) use ($request) {
                $categorySlug = trim((string) $request->input('category_slug'));

                $query->whereHas('category', function ($categoryQuery) use ($categorySlug) {
                    $categoryQuery->where('slug', $categorySlug);
                });
            })
            ->when($request->filled('type'), function ($query) use ($request) {
                $query->where('type', $request->input('type'));
            })
            ->when($request->filled('search'), function ($query) use ($request) {
                $search = trim((string) $request->input('search'));

                $query->where(function ($subQuery) use ($search) {
                    $subQuery
                        ->where('title_ar', 'like', "%{$search}%")
                        ->orWhere('description_ar', 'like', "%{$search}%")
                        ->orWhere('content_ar', 'like', "%{$search}%");
                });
            })
            ->latest()
            ->paginate(20);

        $items->getCollection()->transform(function (LibraryItem $item) use ($userId) {
            return $this->decorateLibraryItemForUser($item, $userId);
        });

        return $this->successResponse($items, 'تم جلب عناصر المكتبة بنجاح');
    }

    public function show(Request $request, LibraryItem $libraryItem)
    {
        if (! $libraryItem->is_published) {
            return $this->errorResponse('هذا العنصر غير متاح حاليًا', null, 404);
        }

        $libraryItem->load('category');

        return $this->successResponse(
            $this->decorateLibraryItemForUser($libraryItem, $request->user()->id),
            'تم جلب تفاصيل عنصر المكتبة بنجاح'
        );
    }

    private function decorateLibraryItemForUser(LibraryItem $item, int $userId): LibraryItem
    {
        $isFavorite = Favorite::query()
            ->where('user_id', $userId)
            ->where('favoritable_type', LibraryItem::class)
            ->where('favoritable_id', $item->id)
            ->exists();

        $coverImageUrl = $this->publicStorageUrl($item->cover_image);
        $fileUrl = $this->publicStorageUrl($item->file_url);

        $item->setAttribute('cover_image_url', $coverImageUrl);
        $item->setAttribute('thumbnail', $coverImageUrl);
        $item->setAttribute('file_path', $item->file_url);
        $item->setAttribute('file_url', $fileUrl);
        $item->setAttribute('category_name', $item->category?->name_ar);
        $item->setAttribute('category_title', $item->category?->name_ar);
        $item->setAttribute('library_category_name', $item->category?->name_ar);
        $item->setAttribute('is_favorite', $isFavorite);
        $item->setAttribute('favorite_type', 'library_item');
        $item->setAttribute('is_accessible', $item->is_free || (float) $item->price <= 0);
        $item->setAttribute('display_price', $item->is_free || (float) $item->price <= 0
            ? 'مجاني'
            : number_format((float) $item->price, 2)
        );

        return $item;
    }

    private function publicStorageUrl(?string $path): ?string
    {
        if ($path === null || trim($path) === '') {
            return null;
        }

        if (str_starts_with($path, 'http://') || str_starts_with($path, 'https://')) {
            return $path;
        }

        $cleanPath = ltrim($path, '/');

        if (str_starts_with($cleanPath, 'storage/')) {
            return url($cleanPath);
        }

        return url(Storage::disk('public')->url($cleanPath));
    }
}
