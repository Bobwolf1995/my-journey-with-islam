<?php

namespace App\Http\Controllers\Api;

use App\Models\Favorite;
use App\Models\Lesson;
use App\Models\LibraryItem;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class FavoriteController extends Controller
{
    public function index(Request $request)
    {
        $type = $request->input('type');

        $favorites = Favorite::query()
            ->where('user_id', $request->user()->id)
            ->when($type, function ($query) use ($type) {
                $modelClass = $this->modelClassForType((string) $type);

                if ($modelClass) {
                    $query->where('favoritable_type', $modelClass);
                }
            })
            ->with('favoritable')
            ->latest()
            ->paginate(20);

        $favorites->getCollection()->transform(function (Favorite $favorite) {
            return $this->formatFavorite($favorite);
        });

        return $this->successResponse($favorites, 'تم جلب المفضلة بنجاح');
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'type' => ['required', 'in:lesson,library_item'],
            'id' => ['required', 'integer', 'min:1'],
        ]);

        $item = $this->findFavoritable(
            type: $validated['type'],
            id: (int) $validated['id']
        );

        if (! $item) {
            return $this->errorResponse('العنصر غير موجود أو غير متاح', null, 404);
        }

        $favorite = Favorite::query()->firstOrCreate([
            'user_id' => $request->user()->id,
            'favoritable_type' => $item::class,
            'favoritable_id' => $item->getKey(),
        ]);

        return $this->successResponse(
            $this->formatFavorite($favorite->load('favoritable')),
            'تمت إضافة العنصر إلى المفضلة بنجاح',
            201
        );
    }

    public function destroy(Request $request)
    {
        $validated = $request->validate([
            'type' => ['required', 'in:lesson,library_item'],
            'id' => ['required', 'integer', 'min:1'],
        ]);

        $modelClass = $this->modelClassForType($validated['type']);

        if (! $modelClass) {
            return $this->errorResponse('نوع العنصر غير مدعوم', null, 422);
        }

        $deleted = Favorite::query()
            ->where('user_id', $request->user()->id)
            ->where('favoritable_type', $modelClass)
            ->where('favoritable_id', $validated['id'])
            ->delete();

        return $this->successResponse([
            'deleted' => $deleted > 0,
        ], 'تم حذف العنصر من المفضلة بنجاح');
    }

    public function toggle(Request $request)
    {
        $validated = $request->validate([
            'type' => ['required', 'in:lesson,library_item'],
            'id' => ['required', 'integer', 'min:1'],
        ]);

        $item = $this->findFavoritable(
            type: $validated['type'],
            id: (int) $validated['id']
        );

        if (! $item) {
            return $this->errorResponse('العنصر غير موجود أو غير متاح', null, 404);
        }

        $favorite = Favorite::query()
            ->where('user_id', $request->user()->id)
            ->where('favoritable_type', $item::class)
            ->where('favoritable_id', $item->getKey())
            ->first();

        if ($favorite) {
            $favorite->delete();

            return $this->successResponse([
                'is_favorite' => false,
                'favorite' => null,
            ], 'تم حذف العنصر من المفضلة');
        }

        $favorite = Favorite::query()->create([
            'user_id' => $request->user()->id,
            'favoritable_type' => $item::class,
            'favoritable_id' => $item->getKey(),
        ]);

        return $this->successResponse([
            'is_favorite' => true,
            'favorite' => $this->formatFavorite($favorite->load('favoritable')),
        ], 'تمت إضافة العنصر إلى المفضلة');
    }

    private function findFavoritable(string $type, int $id): ?Model
    {
        return match ($type) {
            'lesson' => Lesson::query()
                ->where('is_published', true)
                ->find($id),
            'library_item' => LibraryItem::query()
                ->where('is_published', true)
                ->find($id),
            default => null,
        };
    }

    private function formatFavorite(Favorite $favorite): array
    {
        $item = $favorite->favoritable;
        $type = $this->typeForModelClass($favorite->favoritable_type);

        if ($item instanceof Lesson) {
            $item->loadMissing('course');
        }

        $thumbnailPath = $this->thumbnailPathForItem($item);
        $coverImagePath = $this->coverImagePathForItem($item);
        $filePath = $this->filePathForItem($item);
        $videoPath = $this->videoPathForItem($item);
        $audioPath = $this->audioPathForItem($item);

        return [
            'id' => $favorite->id,
            'type' => $type,
            'favoritable_id' => $favorite->favoritable_id,
            'title' => $this->titleForItem($item),
            'description' => $this->descriptionForItem($item),

            'thumbnail_path' => $thumbnailPath,
            'thumbnail' => $this->publicStorageUrl($thumbnailPath),

            'cover_image' => $coverImagePath,
            'cover_image_url' => $this->publicStorageUrl($coverImagePath),

            'file_path' => $filePath,
            'file_url' => $this->publicStorageUrl($filePath),

            'video_path' => $videoPath,
            'video_url' => $this->publicStorageUrl($videoPath),

            'audio_path' => $audioPath,
            'audio_url' => $this->publicStorageUrl($audioPath),

            'created_at' => $favorite->created_at?->toISOString(),
        ];
    }

    private function titleForItem(?Model $item): ?string
    {
        if (! $item) {
            return null;
        }

        return $item->title_ar
            ?? $item->title
            ?? $item->name_ar
            ?? null;
    }

    private function descriptionForItem(?Model $item): ?string
    {
        if (! $item) {
            return null;
        }

        return $item->description_ar
            ?? $item->short_description_ar
            ?? $item->content_ar
            ?? null;
    }

    private function thumbnailPathForItem(?Model $item): ?string
    {
        if (! $item) {
            return null;
        }

        if ($item instanceof LibraryItem) {
            return $item->cover_image;
        }

        if ($item instanceof Lesson) {
            return $item->thumbnail
                ?? $item->cover_image
                ?? $item->course?->cover_image
                ?? null;
        }

        return $item->thumbnail
            ?? $item->cover_image
            ?? null;
    }

    private function coverImagePathForItem(?Model $item): ?string
    {
        if (! $item) {
            return null;
        }

        if ($item instanceof LibraryItem) {
            return $item->cover_image;
        }

        if ($item instanceof Lesson) {
            return $item->cover_image
                ?? $item->course?->cover_image
                ?? null;
        }

        return $item->cover_image ?? null;
    }

    private function filePathForItem(?Model $item): ?string
    {
        if (! $item) {
            return null;
        }

        if ($item instanceof LibraryItem || $item instanceof Lesson) {
            return $item->file_url;
        }

        return null;
    }

    private function videoPathForItem(?Model $item): ?string
    {
        if (! $item) {
            return null;
        }

        if ($item instanceof Lesson) {
            return $item->video_url;
        }

        return null;
    }

    private function audioPathForItem(?Model $item): ?string
    {
        if (! $item) {
            return null;
        }

        if ($item instanceof Lesson) {
            return $item->audio_url;
        }

        return null;
    }

    private function modelClassForType(string $type): ?string
    {
        return match ($type) {
            'lesson' => Lesson::class,
            'library_item' => LibraryItem::class,
            default => null,
        };
    }

    private function typeForModelClass(string $modelClass): string
    {
        return match ($modelClass) {
            Lesson::class => 'lesson',
            LibraryItem::class => 'library_item',
            default => 'unknown',
        };
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