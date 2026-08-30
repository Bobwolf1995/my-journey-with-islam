<?php

namespace App\Http\Controllers\Api;

use App\Models\CourseEnrollment;
use App\Models\Lesson;
use App\Models\Level;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;

class LessonController extends Controller
{
    public function show(Request $request, Lesson $lesson)
    {
        if (! $lesson->is_published) {
            return $this->errorResponse('هذا الدرس غير متاح حاليًا', null, 404);
        }

        $lesson->load(['course', 'section']);

        $contents = $lesson->contents()
            ->where('is_active', true)
            ->orderBy('order')
            ->get()
            ->map(function ($content) {
                return [
                    'id' => $content->id,
                    'type' => $content->type,
                    'title_ar' => $content->title_ar,
                    'content_ar' => $content->content_ar,
                    'media_path' => $content->media_path,
                    'meta' => $content->meta,
                    'order' => $content->order,
                ];
            })
            ->values();

        $quiz = $lesson->quiz()
            ->where('is_active', true)
            ->with([
                'questions' => function ($query) {
                    $query->where('is_active', true)
                        ->orderBy('order')
                        ->with([
                            'options' => function ($query) {
                                $query->orderBy('order');
                            },
                        ]);
                },
            ])
            ->first();

        $quizData = null;

        if ($quiz) {
            $questions = $quiz->questions
                ->map(function ($question) {
                    return [
                        'id' => $question->id,
                        'question_ar' => $question->question_ar,
                        'explanation_ar' => $question->explanation_ar,
                        'order' => $question->order,
                        'points' => $question->points,
                        'options' => $question->options
                            ->map(function ($option) {
                                return [
                                    'id' => $option->id,
                                    'option_ar' => $option->option_ar,
                                    'order' => $option->order,
                                ];
                            })
                            ->values(),
                    ];
                })
                ->values();

            $quizData = [
                'id' => $quiz->id,
                'title_ar' => $quiz->title_ar,
                'description_ar' => $quiz->description_ar,
                'passing_score' => $quiz->passing_score,
                'questions_count' => $questions->count(),
                'questions' => $questions,
            ];
        }

        $isCompleted = $lesson->completions()
            ->where('user_id', $request->user()->id)
            ->exists();

        $videoPath = $lesson->video_url;
        $audioPath = $lesson->audio_url;
        $filePath = $lesson->file_url;

        if ($lesson->course) {
            $courseCoverImageUrl = $this->publicStorageUrl($lesson->course->cover_image);

            $lesson->course->setAttribute('cover_image_url', $courseCoverImageUrl);
            $lesson->course->setAttribute('thumbnail', $courseCoverImageUrl);
        }

        return $this->successResponse([
            'id' => $lesson->id,
            'course_id' => $lesson->course_id,
            'course_section_id' => $lesson->course_section_id,
            'title_ar' => $lesson->title_ar,
            'slug' => $lesson->slug,
            'content_ar' => $lesson->content_ar,
            'lesson_type' => $lesson->lesson_type,

            'video_path' => $videoPath,
            'video_url' => $this->publicStorageUrl($videoPath),
            'audio_path' => $audioPath,
            'audio_url' => $this->publicStorageUrl($audioPath),
            'file_path' => $filePath,
            'file_url' => $this->publicStorageUrl($filePath),

            'duration_minutes' => $lesson->duration_minutes ?? 0,
            'points' => $lesson->points ?? 0,
            'order' => $lesson->order,
            'is_free' => true,
            'can_access' => true,
            'is_locked' => false,
            'lock_reason' => null,
            'is_published' => $lesson->is_published,
            'is_completed' => $isCompleted,
            'course' => $lesson->course,
            'section' => $lesson->section,
            'contents' => $contents,
            'has_quiz' => $quizData !== null,
            'quiz' => $quizData,
        ], 'تم جلب تفاصيل الدرس بنجاح');
    }

    public function complete(Request $request, Lesson $lesson)
    {
        if (! $lesson->is_published) {
            return $this->errorResponse('هذا الدرس غير متاح حاليًا', null, 404);
        }

        if (! $this->canOpenLesson($request, $lesson)) {
            return $this->errorResponse('يجب إكمال الدرس السابق أولًا', null, 403);
        }

        $result = DB::transaction(function () use ($request, $lesson) {
            $user = $request->user();
            $userId = $user->id;

            $completion = $lesson->completions()->firstOrCreate(
                [
                    'user_id' => $userId,
                ],
                [
                    'course_id' => $lesson->course_id,
                    'completed_at' => now(),
                ]
            );

            $wasNewCompletion = $completion->wasRecentlyCreated;

            $profile = $user->profile()->firstOrCreate(
                [],
                [
                    'language' => 'ar',
                    'points' => 0,
                ]
            );

            if ($wasNewCompletion) {
                $profile->increment('points', $lesson->points ?? 0);
                $profile = $profile->fresh();
            }

            $profile->forceFill([
                'last_activity_date' => now()->toDateString(),
                'current_level_id' => $this->levelIdForPoints($profile->points ?? 0),
            ])->save();

            $courseProgress = $this->courseProgressForUser($lesson->course_id, $userId);

            $enrollment = CourseEnrollment::query()->firstOrCreate(
                [
                    'user_id' => $userId,
                    'course_id' => $lesson->course_id,
                ],
                [
                    'status' => 'active',
                    'progress_percentage' => 0,
                    'enrolled_at' => now(),
                ]
            );

            $enrollment->forceFill([
                'status' => $courseProgress['percentage'] >= 100 ? 'completed' : 'active',
                'progress_percentage' => $courseProgress['percentage'],
                'completed_at' => $courseProgress['percentage'] >= 100
                    ? ($enrollment->completed_at ?? now())
                    : null,
            ])->save();

            return [
                'completion' => $completion->fresh(),
                'profile' => $profile->fresh('level'),
                'enrollment' => $enrollment->fresh(),
                'course_progress' => $courseProgress,
                'points_added' => $wasNewCompletion ? ($lesson->points ?? 0) : 0,
                'was_already_completed' => ! $wasNewCompletion,
            ];
        });

        return $this->successResponse([
            'completion' => $result['completion'],
            'course_progress' => $result['course_progress'],
            'enrollment' => $result['enrollment'],
            'profile' => [
                'points' => $result['profile']?->points ?? 0,
                'total_points' => $result['profile']?->points ?? 0,
                'current_level' => $result['profile']?->level,
                'last_activity_date' => $result['profile']?->last_activity_date?->toDateString(),
            ],
            'points_added' => $result['points_added'],
            'was_already_completed' => $result['was_already_completed'],
        ], 'تم إكمال الدرس بنجاح');
    }

    public function submitQuiz(Request $request, Lesson $lesson)
    {
        if (! $lesson->is_published) {
            return $this->errorResponse('هذا الدرس غير متاح حاليًا', null, 404);
        }

        $validated = $request->validate([
            'answers' => ['required', 'array'],
            'answers.*.question_id' => ['required', 'integer', 'distinct', 'exists:quiz_questions,id'],
            'answers.*.option_id' => ['required', 'integer', 'exists:quiz_options,id'],
        ]);

        $quiz = $lesson->quiz()
            ->where('is_active', true)
            ->with([
                'questions' => function ($query) {
                    $query->where('is_active', true)
                        ->orderBy('order')
                        ->with('options');
                },
            ])
            ->first();

        if (! $quiz) {
            return $this->errorResponse('لا يوجد اختبار متاح لهذا الدرس', null, 404);
        }

        $questions = $quiz->questions;
        $questionsCount = $questions->count();

        if ($questionsCount === 0) {
            return $this->errorResponse('لا توجد أسئلة متاحة لهذا الاختبار', null, 422);
        }

        $answers = collect($validated['answers'])->keyBy('question_id');
        $quizQuestionIds = $questions->pluck('id');
        $submittedQuestionIds = $answers->keys();

        if ($submittedQuestionIds->diff($quizQuestionIds)->isNotEmpty()) {
            return $this->errorResponse('بعض الأسئلة لا تتبع هذا الاختبار', null, 422);
        }

        $result = DB::transaction(function () use ($request, $lesson, $quiz, $questions, $questionsCount, $answers) {
            $correctAnswersCount = 0;
            $answerRows = [];

            foreach ($questions as $question) {
                $submittedAnswer = $answers->get($question->id);
                $selectedOption = null;

                if ($submittedAnswer) {
                    $selectedOption = $question->options->firstWhere('id', (int) $submittedAnswer['option_id']);

                    if (! $selectedOption) {
                        throw new \InvalidArgumentException('أحد الخيارات لا يتبع السؤال المحدد');
                    }
                }

                $isCorrect = $selectedOption !== null && (bool) $selectedOption->is_correct;

                if ($isCorrect) {
                    $correctAnswersCount++;
                }

                $answerRows[] = [
                    'question' => $question,
                    'option' => $selectedOption,
                    'is_correct' => $isCorrect,
                    'points_earned' => $isCorrect ? ($question->points ?? 1) : 0,
                ];
            }

            $score = round(($correctAnswersCount / $questionsCount) * 100, 2);
            $passed = $score >= $quiz->passing_score;

            $attempt = $quiz->quizAttempts()->create([
                'user_id' => $request->user()->id,
                'lesson_id' => $lesson->id,
                'course_id' => $lesson->course_id,
                'score' => $score,
                'correct_answers_count' => $correctAnswersCount,
                'questions_count' => $questionsCount,
                'passed' => $passed,
                'started_at' => now(),
                'submitted_at' => now(),
            ]);

            foreach ($answerRows as $answerRow) {
                $attempt->answers()->create([
                    'quiz_question_id' => $answerRow['question']->id,
                    'quiz_option_id' => $answerRow['option']?->id,
                    'is_correct' => $answerRow['is_correct'],
                    'points_earned' => $answerRow['points_earned'],
                ]);
            }

            if ($passed) {
                $lesson->completions()->firstOrCreate(
                    [
                        'user_id' => $request->user()->id,
                    ],
                    [
                        'course_id' => $lesson->course_id,
                        'completed_at' => now(),
                    ]
                );
            }

            return [
                'attempt' => $attempt,
                'score' => $score,
                'passed' => $passed,
                'correct_answers_count' => $correctAnswersCount,
                'questions_count' => $questionsCount,
            ];
        });

        return $this->successResponse([
            'attempt_id' => $result['attempt']->id,
            'score' => $result['score'],
            'passing_score' => $quiz->passing_score,
            'passed' => $result['passed'],
            'correct_answers_count' => $result['correct_answers_count'],
            'questions_count' => $result['questions_count'],
            'message' => $result['passed']
                ? 'أحسنت، لقد اجتزت الاختبار بنجاح'
                : 'لم تجتز الاختبار بعد، حاول مرة أخرى',
        ], 'تم تسليم الاختبار بنجاح');
    }

    private function canAccessLesson(Lesson $lesson, int $userId): bool
    {
        if ((bool) $lesson->is_free) {
            return true;
        }

        return CourseEnrollment::query()
            ->where('course_id', $lesson->course_id)
            ->where('user_id', $userId)
            ->whereIn('status', ['active', 'completed'])
            ->exists();
    }

    private function canOpenLesson(Request $request, Lesson $lesson): bool
    {
        if ($lesson->order === null || $lesson->course_id === null) {
            return true;
        }

        $previousLesson = Lesson::query()
            ->where('course_id', $lesson->course_id)
            ->whereNotNull('order')
            ->where('order', '<', $lesson->order)
            ->where('is_published', true)
            ->orderByDesc('order')
            ->first();

        if (! $previousLesson) {
            return true;
        }

        return $previousLesson->completions()
            ->where('user_id', $request->user()->id)
            ->exists();
    }

    private function courseProgressForUser(int $courseId, int $userId): array
    {
        $lessonIds = Lesson::query()
            ->where('course_id', $courseId)
            ->where('is_published', true)
            ->pluck('id');

        $totalLessons = $lessonIds->count();

        if ($totalLessons === 0) {
            return [
                'course_id' => $courseId,
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
            'course_id' => $courseId,
            'total_lessons' => $totalLessons,
            'completed_lessons' => $completedLessons,
            'percentage' => $percentage,
            'progress_percentage' => $percentage,
        ];
    }

    private function levelIdForPoints(int $points): ?int
    {
        return Level::query()
            ->where('is_active', true)
            ->where('required_points', '<=', $points)
            ->orderByDesc('required_points')
            ->orderByDesc('order')
            ->value('id');
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