<?php

namespace App\Http\Controllers\Api;

use App\Models\Notification;
use Illuminate\Http\Request;

class NotificationController extends Controller
{
    public function index(Request $request)
    {
        $notifications = Notification::query()
            ->where(function ($query) use ($request) {
                $query
                    ->where('user_id', $request->user()->id)
                    ->orWhereNull('user_id');
            })
            ->latest()
            ->paginate(20);

        $notifications->through(function (Notification $notification) {
            return $this->formatNotification($notification);
        });

        return $this->successResponse($notifications, 'تم جلب الإشعارات بنجاح');
    }

    public function markAsRead(Request $request, Notification $notification)
    {
        if ($notification->user_id !== null && $notification->user_id !== $request->user()->id) {
            return $this->errorResponse('لا تملك صلاحية تعديل هذا الإشعار', null, 403);
        }

        if ($notification->read_at === null) {
            $notification->forceFill([
                'read_at' => now(),
            ])->save();
        }

        return $this->successResponse(
            $this->formatNotification($notification->fresh()),
            'تم تعليم الإشعار كمقروء'
        );
    }

    private function formatNotification(Notification $notification): array
    {
        $data = $notification->data ?? [];

        return [
            'id' => $notification->id,
            'user_id' => $notification->user_id,
            'title' => $notification->title_ar,
            'title_ar' => $notification->title_ar,
            'body' => $notification->body_ar,
            'body_ar' => $notification->body_ar,
            'type' => $notification->type,
            'data' => $data,
            'screen' => $data['screen'] ?? $data['route'] ?? null,
            'target_id' => $data['target_id'] ?? $data['id'] ?? null,
            'is_read' => $notification->read_at !== null,
            'read_at' => $notification->read_at?->toDateTimeString(),
            'created_at' => $notification->created_at?->toDateTimeString(),
            'updated_at' => $notification->updated_at?->toDateTimeString(),
        ];
    }
}