<?php

namespace App\Http\Controllers\Api;

use App\Models\Course;
use App\Models\CourseEnrollment;
use App\Models\LearningPath;
use App\Models\Lesson;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;

class CourseController extends Controller
{
    public function learningPaths()
    {
        $paths = LearningPath::query()
            ->where('is_active', true)
            ->orderBy('order')
            ->get();

        return $this->successResponse($paths, 'تم جلب المسارات التعليمية بنجاح');
    }

    public function showLearningPath(Request $request, LearningPath $learningPath)
    {
        $userId = $request->user()->id;

        $learningPath->load([
            'courses' => fn ($query) => $query
                ->where('is_published', true)
                ->orderBy('order'),
        ]);

        $learningPath->courses->transform(function (Course $course) use ($userId) {
            return $this->decorateCourseForUser($course, $userId);
        });

        return $this->successResponse($learningPath, 'تم جلب تفاصيل المسار بنجاح');
    }

    public function index(Request $request)
    {
        $userId = $request->user()->id;

        $courses = Course::query()
            ->with('learningPath')
            ->where('is_published', true)
            ->when($request->filled('learning_path_id'), function ($query) use ($request) {
                $query->where('learning_path_id', $request->integer('learning_path_id'));
            })
            ->when($request->filled('level'), function ($query) use ($request) {
                $query->where('level', $request->input('level'));
            })
            ->orderBy('order')
            ->paginate(15);

        $courses->getCollection()->transform(function (Course $course) use ($userId) {
            return $this->decorateCourseForUser($course, $userId);
        });

        return $this->successResponse($courses, 'تم جلب الدورات بنجاح');
    }

    public function show(Request $request, Course $course)
    {
        if (! $course->is_published) {
            return $this->errorResponse('هذه الدورة غير متاحة حاليًا', null, 404);
        }

        $userId = $request->user()->id;

        $course->load([
            'learningPath',
            'sections.lessons' => fn ($query) => $query
                ->where('is_published', true)
                ->orderBy('order'),
            'lessons' => fn ($query) => $query
                ->whereNull('course_section_id')
                ->where('is_published', true)
                ->orderBy('order'),
        ]);

        $this->decorateCourseForUser($course, $userId);

        $canAccessPaidLessons = true;

        $this->markLessonsCompletion($course, $userId);
        $this->decorateCourseLessonsAccess($course, $canAccessPaidLessons);
        $this->decorateCourseLessonsMedia($course);

        return $this->successResponse($course, 'تم جلب تفاصيل الدورة بنجاح');
    }

    public function enroll(Request $request, Course $course)
    {
        if (! $course->is_published) {
            return $this->errorResponse('هذه الدورة غير متاحة حاليًا', null, 404);
        }

        $userId = $request->user()->id;
        $progress = $this->courseProgressForUser($course, $userId);

        $enrollment = $course->enrollments()->firstOrCreate(
            [
                'user_id' => $userId,
            ],
            [
                'status' => 'active',
                'progress_percentage' => 0,
                'enrolled_at' => now(),
            ]
        );

        $this->syncEnrollmentProgress($enrollment, $progress);

        $enrollment = $enrollment->fresh();
        $enrollment->setAttribute('is_enrolled', true);
        $enrollment->setAttribute('course_progress', $progress);
        $enrollment->setAttribute('progress', $progress['percentage']);
        $enrollment->setAttribute('percentage', $progress['percentage']);

        return $this->successResponse($enrollment, 'تم التسجيل في الدورة بنجاح', 201);
    }

    public function progress(Request $request, Course $course)
    {
        if (! $course->is_published) {
            return $this->errorResponse('هذه الدورة غير متاحة حاليًا', null, 404);
        }

        $userId = $request->user()->id;
        $progress = $this->courseProgressForUser($course, $userId);
        $enrollment = $this->enrollmentForUser($course->id, $userId);

        if ($enrollment) {
            $this->syncEnrollmentProgress($enrollment, $progress);
            $enrollment = $enrollment->fresh();
        }

        return $this->successResponse([
            'course_id' => $course->id,
            'total_lessons' => $progress['total_lessons'],
            'completed_lessons' => $progress['completed_lessons'],
            'percentage' => $progress['percentage'],
            'progress' => $progress['percentage'],
            'progress_percentage' => $progress['percentage'],
            'is_enrolled' => $enrollment !== null,
            'enrollment_status' => $enrollment?->status,
            'enrollment' => $enrollment,
        ], 'تم جلب تقدم الدورة بنجاح');
    }

    private function decorateCourseForUser(Course $course, int $userId): Course
    {
        $progress = $this->courseProgressForUser($course, $userId);
        $enrollment = $this->enrollmentForUser($course->id, $userId);
        $coverImageUrl = $this->publicStorageUrl($course->cover_image);

        if ($enrollment) {
            $this->syncEnrollmentProgress($enrollment, $progress);
            $enrollment = $enrollment->fresh();
        }

        $canAccessPaidLessons = (bool) $course->is_free
            || ($enrollment !== null
                && in_array($enrollment->status, ['active', 'completed'], true));

        $course->setAttribute('lessons_count', $progress['total_lessons']);
        $course->setAttribute('total_lessons', $progress['total_lessons']);
        $course->setAttribute('completed_lessons', $progress['completed_lessons']);
        $course->setAttribute('progress', $progress['percentage']);
        $course->setAttribute('percentage', $progress['percentage']);
        $course->setAttribute('progress_percentage', $progress['percentage']);
        $course->setAttribute('cover_image_url', $coverImageUrl);
        $course->setAttribute('thumbnail', $coverImageUrl);
        $course->setAttribute('is_enrolled', $enrollment !== null);
        $course->setAttribute('enrollment_status', $enrollment?->status);
        $course->setAttribute('can_access_paid_lessons', $canAccessPaidLessons);
        $course->setAttribute('enrollment', $enrollment);

        return $course;
    }

    private function decorateCourseLessonsAccess(Course $course, bool $canAccessPaidLessons): void
    {
        foreach ($course->sections as $section) {
            foreach ($section->lessons as $lesson) {
                $this->decorateLessonAccess($lesson, $canAccessPaidLessons);
            }
        }

        foreach ($course->lessons as $lesson) {
            $this->decorateLessonAccess($lesson, $canAccessPaidLessons);
        }
    }

    private function decorateLessonAccess(Lesson $lesson, bool $canAccessPaidLessons): Lesson
    {
        $lesson->setAttribute('is_free', true);
        $lesson->setAttribute('can_access', true);
        $lesson->setAttribute('is_locked', false);
        $lesson->setAttribute('lock_reason', null);

        return $lesson;
    }

    private function decorateCourseLessonsMedia(Course $course): void
    {
        foreach ($course->sections as $section) {
            foreach ($section->lessons as $lesson) {
                $this->decorateLessonMedia($lesson);
            }
        }

        foreach ($course->lessons as $lesson) {
            $this->decorateLessonMedia($lesson);
        }
    }

    private function decorateLessonMedia(Lesson $lesson): Lesson
    {
        $lesson->setAttribute('file_path', $lesson->file_url);
        $lesson->setAttribute('video_path', $lesson->video_url);
        $lesson->setAttribute('audio_path', $lesson->audio_url);
        $lesson->setAttribute('file_url', $this->publicStorageUrl($lesson->file_url));
        $lesson->setAttribute('video_url', $this->publicStorageUrl($lesson->video_url));
        $lesson->setAttribute('audio_url', $this->publicStorageUrl($lesson->audio_url));

        return $lesson;
    }

    private function courseProgressForUser(Course $course, int $userId): array
    {
        $lessonIds = DB::table('lessons')
            ->where('course_id', $course->id)
            ->where('is_published', true)
            ->pluck('id');

        $totalLessons = $lessonIds->count();

        if ($totalLessons === 0) {
            return [
                'course_id' => $course->id,
                'total_lessons' => 0,
                'completed_lessons' => 0,
                'percentage' => 0,
                'progress_percentage' => 0,
            ];
        }

        $completedLessons = DB::table('lesson_completions')
            ->where('user_id', $userId)
            ->whereIn('lesson_id', $lessonIds)
            ->distinct()
            ->count('lesson_id');

        $percentage = (int) round(($completedLessons / $totalLessons) * 100);

        return [
            'course_id' => $course->id,
            'total_lessons' => $totalLessons,
            'completed_lessons' => $completedLessons,
            'percentage' => $percentage,
            'progress_percentage' => $percentage,
        ];
    }

    private function enrollmentForUser(int $courseId, int $userId): ?CourseEnrollment
    {
        return CourseEnrollment::query()
            ->where('course_id', $courseId)
            ->where('user_id', $userId)
            ->first();
    }

    private function canAccessPaidLessons(int $courseId, int $userId): bool
    {
        return CourseEnrollment::query()
            ->where('course_id', $courseId)
            ->where('user_id', $userId)
            ->whereIn('status', ['active', 'completed'])
            ->exists();
    }

    private function syncEnrollmentProgress(CourseEnrollment $enrollment, array $progress): void
    {
        $isCompleted = $progress['percentage'] >= 100;

        $enrollment->forceFill([
            'status' => $isCompleted ? 'completed' : 'active',
            'progress_percentage' => $progress['percentage'],
            'completed_at' => $isCompleted
                ? ($enrollment->completed_at ?? now())
                : null,
        ])->save();
    }

    private function markLessonsCompletion(Course $course, int $userId): void
    {
        $lessonIds = DB::table('lessons')
            ->where('course_id', $course->id)
            ->pluck('id');

        $completedLessonIds = DB::table('lesson_completions')
            ->where('user_id', $userId)
            ->whereIn('lesson_id', $lessonIds)
            ->pluck('lesson_id')
            ->map(fn ($lessonId) => (int) $lessonId)
            ->all();

        foreach ($course->sections as $section) {
            foreach ($section->lessons as $lesson) {
                $lesson->setAttribute(
                    'is_completed',
                    in_array((int) $lesson->id, $completedLessonIds, true)
                );
            }
        }

        foreach ($course->lessons as $lesson) {
            $lesson->setAttribute(
                'is_completed',
                in_array((int) $lesson->id, $completedLessonIds, true)
            );
        }
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
