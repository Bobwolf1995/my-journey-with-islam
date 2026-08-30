<?php

namespace App\Http\Controllers\Api;

use App\Models\User;
use Illuminate\Http\Request;

class MentorController extends Controller
{
    public function myMentor(Request $request)
    {
        $mentorStudent = $request->user()
            ->mentorRelationsAsStudent()
            ->with('mentor.user.profile')
            ->latest()
            ->first();

        return $this->successResponse(
            $mentorStudent?->mentor,
            'تم جلب بيانات المرشد بنجاح'
        );
    }

    public function students(Request $request)
    {
        $mentor = $request->user()->mentor;

        if (! $mentor) {
            return $this->errorResponse('هذا الحساب ليس مرشدًا', null, 403);
        }

        $students = $mentor->students()
            ->with('student.profile')
            ->latest()
            ->paginate(20);

        return $this->successResponse($students, 'تم جلب الطلاب بنجاح');
    }

    public function studentProgress(Request $request, User $student)
    {
        $mentor = $request->user()->mentor;

        if (! $mentor || ! $mentor->students()->where('student_id', $student->id)->exists()) {
            return $this->errorResponse('لا تملك صلاحية عرض هذا الطالب', null, 403);
        }

        $student->load('profile');
        $points = $student->profile?->points ?? 0;

        return $this->successResponse([
            'student' => $student,
            'courses_completed' => 0,
            'lessons_completed' => $student->lessonCompletions()->count(),
            'tasks_completed' => $student->userTasks()->where('status', 'completed')->count(),
            'points' => $points,
            'total_points' => $points,
        ], 'تم جلب تقدم الطالب بنجاح');
    }

    public function storeNote(Request $request, User $student)
    {
        $validated = $request->validate([
            'note' => ['required', 'string', 'max:2000'],
        ]);

        $mentor = $request->user()->mentor;

        if (! $mentor || ! $mentor->students()->where('student_id', $student->id)->exists()) {
            return $this->errorResponse('لا تملك صلاحية إضافة ملاحظة لهذا الطالب', null, 403);
        }

        $note = $mentor->notes()->create([
            'student_id' => $student->id,
            'note' => $validated['note'],
        ]);

        return $this->successResponse($note, 'تمت إضافة الملاحظة بنجاح', 201);
    }
}