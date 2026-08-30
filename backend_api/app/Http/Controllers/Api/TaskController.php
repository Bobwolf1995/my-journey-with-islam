<?php

namespace App\Http\Controllers\Api;

use App\Models\Task;
use Illuminate\Http\Request;

class TaskController extends Controller
{
    public function index(Request $request)
    {
        $tasks = Task::query()
            ->where('is_active', true)
            ->with(['userTasks' => function ($query) use ($request) {
                $query->where('user_id', $request->user()->id);
            }])
            ->orderBy('type')
            ->orderBy('order')
            ->latest()
            ->get();

        return $this->successResponse($tasks, 'تم جلب المهام بنجاح');
    }

    public function complete(Request $request, Task $task)
    {
        if (! $task->is_active) {
            return $this->errorResponse('هذه المهمة غير متاحة حاليًا', null, 404);
        }

        $userTask = $task->userTasks()
            ->where('user_id', $request->user()->id)
            ->first();

        $wasCompleted = $userTask?->status === 'completed';

        if ($userTask) {
            $userTask->update([
                'status' => 'completed',
                'completed_at' => $userTask->completed_at ?? now(),
            ]);
        } else {
            $userTask = $task->userTasks()->create([
                'user_id' => $request->user()->id,
                'status' => 'completed',
                'completed_at' => now(),
            ]);
        }

        $profile = $request->user()->profile;

        if ($profile && ! $wasCompleted) {
            $profile->increment('points', $task->points);
        }

        return $this->successResponse($userTask->fresh(), 'تم إكمال المهمة بنجاح');
    }
}