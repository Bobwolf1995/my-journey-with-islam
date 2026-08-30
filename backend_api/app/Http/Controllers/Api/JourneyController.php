<?php

namespace App\Http\Controllers\Api;

use App\Models\Course;
use App\Models\LearningPath;
use App\Models\Lesson;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class JourneyController extends Controller
{
    public function index(Request $request)
    {
        $userId = $request->user()->id;

        $completedLessonIds = DB::table('lesson_completions')
            ->where('user_id', $userId)
            ->distinct()
            ->pluck('lesson_id')
            ->map(fn ($lessonId) => (int) $lessonId)
            ->all();

        $publishedLessonIds = Lesson::query()
            ->where('is_published', true)
            ->pluck('id')
            ->map(fn ($lessonId) => (int) $lessonId)
            ->all();

        $totalLessons = count($publishedLessonIds);
        $completedLessons = count(array_intersect($publishedLessonIds, $completedLessonIds));

        $overallPercentage = $totalLessons > 0
            ? (int) round(($completedLessons / $totalLessons) * 100)
            : 0;

        $paths = LearningPath::query()
            ->where('is_active', true)
            ->with([
                'courses' => function ($query) {
                    $query
                        ->where('is_published', true)
                        ->with([
                            'lessons' => function ($lessonQuery) {
                                $lessonQuery
                                    ->where('is_published', true)
                                    ->orderBy('order');
                            },
                        ])
                        ->orderBy('order');
                },
            ])
            ->orderBy('order')
            ->get()
            ->map(function (LearningPath $path) use ($completedLessonIds) {
                $courses = $path->courses
                    ->map(function (Course $course) use ($completedLessonIds) {
                        return $this->formatCourseForJourney($course, $completedLessonIds);
                    })
                    ->values();

                $totalLessons = $courses->sum('total_lessons');
                $completedLessons = $courses->sum('completed_lessons');

                $percentage = $totalLessons > 0
                    ? (int) round(($completedLessons / $totalLessons) * 100)
                    : 0;

                return [
                    'id' => $path->id,
                    'name_ar' => $path->name_ar,
                    'title_ar' => $path->name_ar,
                    'slug' => $path->slug,
                    'description_ar' => $path->description_ar,
                    'icon' => $path->icon,
                    'color' => $path->color,
                    'order' => $path->order,
                    'courses_count' => $courses->count(),
                    'total_lessons' => $totalLessons,
                    'completed_lessons' => $completedLessons,
                    'progress' => $percentage,
                    'progress_percentage' => $percentage,
                    'status' => $this->statusForProgress($percentage, $completedLessons),
                    'courses' => $courses,
                ];
            })
            ->values();

        return $this->successResponse([
            'title' => 'رحلتي مع الإسلام',
            'subtitle' => 'تابع خطواتك وإنجازاتك في التعلم والعمل',
            'statistics' => [
                'total_lessons' => $totalLessons,
                'completed_lessons' => $completedLessons,
                'progress' => $overallPercentage,
                'progress_percentage' => $overallPercentage,
                'status' => $this->statusForProgress($overallPercentage, $completedLessons),
            ],
            'paths' => $paths,
            'items' => $paths,
        ], 'تم جلب بيانات الرحلة بنجاح');
    }

    private function formatCourseForJourney(Course $course, array $completedLessonIds): array
    {
        $lessonIds = $course->lessons
            ->pluck('id')
            ->map(fn ($lessonId) => (int) $lessonId)
            ->all();

        $totalLessons = count($lessonIds);
        $completedLessons = count(array_intersect($lessonIds, $completedLessonIds));

        $percentage = $totalLessons > 0
            ? (int) round(($completedLessons / $totalLessons) * 100)
            : 0;

        $nextLesson = $course->lessons->first(function (Lesson $lesson) use ($completedLessonIds) {
            return ! in_array((int) $lesson->id, $completedLessonIds, true);
        });

        return [
            'id' => $course->id,
            'learning_path_id' => $course->learning_path_id,
            'title_ar' => $course->title_ar,
            'slug' => $course->slug,
            'description_ar' => $course->description_ar,
            'short_description_ar' => $course->short_description_ar,
            'cover_image' => $course->cover_image,
            'thumbnail' => $course->cover_image,
            'level' => $course->level,
            'duration_minutes' => $course->duration_minutes,
            'lessons_count' => $totalLessons,
            'total_lessons' => $totalLessons,
            'completed_lessons' => $completedLessons,
            'progress' => $percentage,
            'progress_percentage' => $percentage,
            'order' => $course->order,
            'is_featured' => $course->is_featured,
            'is_published' => $course->is_published,
            'published_at' => $course->published_at?->toISOString(),
            'status' => $this->statusForProgress($percentage, $completedLessons),
            'next_lesson' => $nextLesson
                ? [
                    'id' => $nextLesson->id,
                    'title_ar' => $nextLesson->title_ar,
                    'order' => $nextLesson->order,
                ]
                : null,
        ];
    }

    private function statusForProgress(int $percentage, int $completedLessons): string
    {
        if ($percentage >= 100) {
            return 'completed';
        }

        if ($completedLessons > 0) {
            return 'in_progress';
        }

        return 'available';
    }
}