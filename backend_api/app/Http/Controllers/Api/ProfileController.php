<?php

namespace App\Http\Controllers\Api;

use App\Models\Level;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class ProfileController extends Controller
{
    public function show(Request $request)
    {
        $user = $request->user()->load([
            'profile.level',
            'badges',
            'roles',
        ]);

        $this->decorateProfileForResponse($user);

        return $this->successResponse([
            'user' => $user,
            'statistics' => $this->statisticsForUser($user),
        ], 'تم جلب الملف الشخصي بنجاح');
    }

    public function stats(Request $request)
    {
        $user = $request->user()->load([
            'profile.level',
            'badges',
            'roles',
        ]);

        return $this->successResponse(
            $this->statisticsForUser($user),
            'تم جلب إحصائيات الملف الشخصي بنجاح'
        );
    }

    public function update(Request $request)
    {
        $validated = $request->validate([
            'name' => ['nullable', 'string', 'max:120'],
            'display_name' => ['nullable', 'string', 'max:120'],
            'phone' => ['nullable', 'string', 'max:30'],
            'bio' => ['nullable', 'string', 'max:1000'],
            'country' => ['nullable', 'string', 'max:120'],
            'city' => ['nullable', 'string', 'max:120'],
            'language' => ['nullable', 'in:ar,en'],
        ]);

        $user = $request->user();

        $user->update([
            'name' => $validated['name'] ?? $user->name,
            'phone' => $validated['phone'] ?? $user->phone,
        ]);

        $profile = $user->profile;

        $user->profile()->updateOrCreate(
            [
                'user_id' => $user->id,
            ],
            [
                'display_name' => $validated['display_name']
                    ?? $validated['name']
                    ?? $profile?->display_name
                    ?? $user->name,
                'bio' => $validated['bio'] ?? $profile?->bio,
                'country' => $validated['country'] ?? $profile?->country,
                'city' => $validated['city'] ?? $profile?->city,
                'language' => $validated['language'] ?? $profile?->language ?? 'ar',
            ]
        );

        $freshUser = $user->fresh()->load([
            'profile.level',
            'badges',
            'roles',
        ]);

        $this->decorateProfileForResponse($freshUser);

        return $this->successResponse(
            $freshUser,
            'تم تحديث الملف الشخصي بنجاح'
        );
    }

    private function statisticsForUser($user): array
    {
        $profile = $user->profile;
        $points = $profile?->points ?? 0;
        $currentLevel = $this->currentLevelForPoints($points, $profile?->level);
        $nextLevel = $this->nextLevelForPoints($points);

        $totalPublishedCourses = DB::table('courses')
            ->where('is_published', true)
            ->count();

        $totalPublishedLessons = DB::table('lessons')
            ->where('is_published', true)
            ->count();

        $completedLessonsCount = $user->lessonCompletions()
            ->distinct()
            ->count('lesson_id');

        $completedTasksCount = $user->userTasks()
            ->where('status', 'completed')
            ->count();

        $coursesCount = $user->courseEnrollments()->count();

        $lessonCompletionPercentage = $totalPublishedLessons > 0
            ? (int) round(($completedLessonsCount / $totalPublishedLessons) * 100)
            : 0;

        return [
            'courses_count' => $coursesCount,
            'enrolled_courses_count' => $coursesCount,
            'total_courses_count' => $totalPublishedCourses,
            'completed_lessons_count' => $completedLessonsCount,
            'total_lessons_count' => $totalPublishedLessons,
            'lesson_completion_percentage' => $lessonCompletionPercentage,
            'completed_tasks_count' => $completedTasksCount,
            'badges_count' => $user->badges()->count(),
            'points' => $points,
            'total_points' => $points,
            'streak_days' => $profile?->streak_days ?? 0,
            'last_activity_date' => $profile?->last_activity_date?->toDateString(),
            'current_level' => $this->formatLevel($currentLevel),
            'next_level' => $this->formatLevel($nextLevel),
            'points_to_next_level' => $nextLevel
                ? max(0, $nextLevel->required_points - $points)
                : 0,
        ];
    }

    private function decorateProfileForResponse($user): void
    {
        if (! $user->profile) {
            return;
        }

        $points = $user->profile->points ?? 0;
        $currentLevel = $this->currentLevelForPoints($points, $user->profile->level);
        $nextLevel = $this->nextLevelForPoints($points);

        $user->profile->setAttribute('points', $points);
        $user->profile->setAttribute('total_points', $points);
        $user->profile->setAttribute('role', $this->roleLabelForUser($user));
        $user->profile->setAttribute('role_key', $this->roleKeyForUser($user));
        $user->profile->setAttribute('current_level', $this->formatLevel($currentLevel));
        $user->profile->setAttribute('next_level', $this->formatLevel($nextLevel));
        $user->profile->setAttribute('points_to_next_level', $nextLevel
            ? max(0, $nextLevel->required_points - $points)
            : 0
        );

        if (! $user->profile->display_name) {
            $user->profile->setAttribute('display_name', $user->name);
        }
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

    private function nextLevelForPoints(int $points): ?Level
    {
        return Level::query()
            ->where('is_active', true)
            ->where('required_points', '>', $points)
            ->orderBy('required_points')
            ->orderBy('order')
            ->first();
    }

    private function formatLevel(?Level $level): ?array
    {
        if (! $level) {
            return null;
        }

        return [
            'id' => $level->id,
            'name_ar' => $level->name_ar,
            'slug' => $level->slug,
            'description_ar' => $level->description_ar,
            'required_points' => $level->required_points,
            'icon' => $level->icon,
            'color' => $level->color,
            'order' => $level->order,
        ];
    }

    private function roleKeyForUser($user): string
    {
        $roleName = $user->roles?->pluck('name')->first();

        return $roleName
            ?? $user->account_type
            ?? 'user';
    }

    private function roleLabelForUser($user): string
    {
        return match ($this->roleKeyForUser($user)) {
            'admin' => 'مدير المنصة',
            'supervisor' => 'مشرف',
            'teacher' => 'معلم',
            'mentor' => 'مرشد',
            'student', 'user' => 'طالب علم',
            default => 'مستخدم',
        };
    }
}