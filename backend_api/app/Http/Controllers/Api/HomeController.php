<?php

namespace App\Http\Controllers\Api;

use App\Models\Badge;
use App\Models\Lesson;
use App\Models\Level;
use App\Models\Notification;
use App\Models\Task;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class HomeController extends Controller
{
    public function index(Request $request)
    {
        $user = $request->user()->load(['profile.level']);
        $userId = $user->id;
        $points = $user->profile?->points ?? 0;
        $currentLevel = $this->currentLevelForPoints($points, $user->profile?->level);

        $progress = $this->overallProgress($userId, $currentLevel);
        $nextLesson = $this->nextLesson($userId);
        $dailyTasks = $this->dailyTasks($userId);
        $latestBadge = $this->latestBadgeData($user, $points);
        $latestMessage = $this->latestMessage($userId);

        $unreadNotificationsCount = Notification::query()
            ->where(function ($query) use ($userId) {
                $query
                    ->where('user_id', $userId)
                    ->orWhereNull('user_id');
            })
            ->whereNull('read_at')
            ->count();

        return $this->successResponse([
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'avatar' => $user->profile?->avatar,
                'rank' => $currentLevel?->name_ar ?? $user->profile?->level?->name_ar,
                'points' => $points,
                'total_points' => $points,
                'current_level' => $currentLevel,
            ],
            'progress' => $progress,
            'next_lesson' => $nextLesson,
            'daily_tasks' => $dailyTasks,
            'shortcuts' => $this->shortcuts(),
            'latest_badge' => $latestBadge,
            'latest_message' => $latestMessage,
            'unread_notifications_count' => $unreadNotificationsCount,
        ], 'تم جلب بيانات الصفحة الرئيسية بنجاح');
    }

    private function currentLevelForPoints(int $points, ?Level $profileLevel): ?Level
    {
        if ($profileLevel) {
            return $profileLevel;
        }

        return Level::query()
            ->where('is_active', true)
            ->where('required_points', '<=', $points)
            ->orderByDesc('required_points')
            ->orderByDesc('order')
            ->first();
    }

    private function overallProgress(int $userId, ?Level $currentLevel): array
    {
        $totalLessons = Lesson::query()
            ->where('is_published', true)
            ->count();

        $completedLessons = DB::table('lesson_completions')
            ->where('user_id', $userId)
            ->distinct()
            ->count('lesson_id');

        $percentage = $totalLessons > 0
            ? (int) round(($completedLessons / $totalLessons) * 100)
            : 0;

        return [
            'percentage' => $percentage,
            'current_level' => $currentLevel?->name_ar,
            'current_level_id' => $currentLevel?->id,
            'current_level_icon' => $currentLevel?->icon,
            'current_level_color' => $currentLevel?->color,
            'message' => $this->progressMessage($percentage, $completedLessons, $totalLessons),
            'completed_lessons' => $completedLessons,
            'total_lessons' => $totalLessons,
        ];
    }

    private function progressMessage(int $percentage, int $completedLessons, int $totalLessons): string
    {
        if ($totalLessons === 0) {
            return 'ستظهر رحلتك هنا بعد إضافة الدروس.';
        }

        if ($percentage >= 100) {
            return 'أتممت جميع الدروس المتاحة بنجاح.';
        }

        if ($completedLessons > 0) {
            return 'واصل التقدم، بقيت لك دروس جديدة.';
        }

        return 'ابدأ أول درس في رحلتك التعليمية.';
    }

    private function nextLesson(int $userId): array
    {
        $lesson = Lesson::query()
            ->with('course')
            ->where('is_published', true)
            ->whereHas('course', function ($query) {
                $query->where('is_published', true);
            })
            ->whereNotIn('id', function ($query) use ($userId) {
                $query
                    ->select('lesson_id')
                    ->from('lesson_completions')
                    ->where('user_id', $userId);
            })
            ->orderBy('course_id')
            ->orderBy('order')
            ->first();

        if (! $lesson) {
            return [
                'id' => null,
                'course_id' => null,
                'title' => null,
                'title_ar' => null,
                'course_title' => null,
                'thumbnail' => null,
                'is_completed' => true,
            ];
        }

        return [
            'id' => $lesson->id,
            'course_id' => $lesson->course_id,
            'title' => $lesson->title_ar,
            'title_ar' => $lesson->title_ar,
            'course_title' => $lesson->course?->title_ar,
            'thumbnail' => $lesson->course?->cover_image,
            'is_completed' => false,
        ];
    }

    private function dailyTasks(int $userId): array
    {
        return Task::query()
            ->where('is_active', true)
            ->with(['userTasks' => function ($query) use ($userId) {
                $query->where('user_id', $userId);
            }])
            ->orderBy('order')
            ->limit(3)
            ->get()
            ->map(function (Task $task) {
                $userTask = $task->userTasks->first();

                return [
                    'id' => $task->id,
                    'title' => $task->title_ar,
                    'title_ar' => $task->title_ar,
                    'description_ar' => $task->description_ar,
                    'type' => $task->type,
                    'points' => $task->points ?? 0,
                    'is_completed' => $userTask?->status === 'completed',
                    'completed_at' => $userTask?->completed_at,
                ];
            })
            ->values()
            ->all();
    }

    private function latestBadgeData($user, int $points): ?array
    {
        $latestUserBadge = $user->badges()
            ->latest('user_badges.created_at')
            ->first();

        if ($latestUserBadge) {
            return [
                'id' => $latestUserBadge->id,
                'title' => $latestUserBadge->name_ar,
                'name_ar' => $latestUserBadge->name_ar,
                'description_ar' => $latestUserBadge->description_ar,
                'icon' => $latestUserBadge->icon,
                'is_awarded' => true,
                'awarded_at' => $latestUserBadge->pivot?->awarded_at,
            ];
        }

        $availableBadge = Badge::query()
            ->where('is_active', true)
            ->where('required_points', '<=', $points)
            ->orderByDesc('required_points')
            ->first();

        if (! $availableBadge) {
            return null;
        }

        return [
            'id' => $availableBadge->id,
            'title' => $availableBadge->name_ar,
            'name_ar' => $availableBadge->name_ar,
            'description_ar' => $availableBadge->description_ar,
            'icon' => $availableBadge->icon,
            'is_awarded' => false,
            'awarded_at' => null,
        ];
    }

    private function latestMessage(int $userId): ?array
    {
        $conversationIds = DB::table('conversation_participants')
            ->where('user_id', $userId)
            ->pluck('conversation_id');

        if ($conversationIds->isEmpty()) {
            return null;
        }

        $message = DB::table('messages')
            ->whereIn('conversation_id', $conversationIds)
            ->where('sender_id', '!=', $userId)
            ->latest()
            ->first();

        if (! $message) {
            return null;
        }

        $senderName = DB::table('users')
            ->where('id', $message->sender_id)
            ->value('name');

        return [
            'from' => $senderName,
            'message' => $message->body,
            'created_at' => $message->created_at,
        ];
    }

    private function shortcuts(): array
    {
        return [
            [
                'key' => 'courses',
                'title' => 'دوراتي',
                'icon' => 'courses',
            ],
            [
                'key' => 'library',
                'title' => 'المكتبة',
                'icon' => 'library',
            ],
            [
                'key' => 'community',
                'title' => 'المجتمع',
                'icon' => 'community',
            ],
            [
                'key' => 'mentor',
                'title' => 'المرشد',
                'icon' => 'mentor',
            ],
        ];
    }
}