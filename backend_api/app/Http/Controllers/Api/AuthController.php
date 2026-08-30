<?php

namespace App\Http\Controllers\Api;

use App\Models\Level;
use App\Models\User;
use Illuminate\Auth\Events\PasswordReset;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Password;
use Illuminate\Support\Str;
use Illuminate\Validation\Rules\Password as PasswordRule;

class AuthController extends Controller
{
    public function register(Request $request)
    {
        $validated = $request->validate([
            'name' => ['required', 'string', 'max:120'],
            'email' => ['required', 'email', 'max:190', 'unique:users,email'],
            'phone' => ['nullable', 'string', 'max:30'],
            'password' => ['required', 'confirmed', PasswordRule::min(8)],
            'account_type' => ['required', 'in:user,mentor,teacher,supervisor,admin'],
        ]);

        $user = DB::transaction(function () use ($validated) {
            $user = User::create([
                'name' => $validated['name'],
                'email' => $validated['email'],
                'phone' => $validated['phone'] ?? null,
                'password' => Hash::make($validated['password']),
                'account_type' => $validated['account_type'],
                'status' => 'active',
            ]);

            $user->profile()->create([
                'language' => 'ar',
                'points' => 0,
            ]);

            if (method_exists($user, 'assignRole')) {
                $user->assignRole($this->roleNameForAccountType($validated['account_type']));
            }

            return $user;
        });

        $token = $user->createToken('mobile-app')->plainTextToken;

        return $this->successResponse([
            'token' => $token,
            'user' => $user->load('profile'),
        ], 'تم إنشاء الحساب بنجاح', 201);
    }

    public function login(Request $request)
    {
        $validated = $request->validate([
            'email' => ['required', 'email'],
            'password' => ['required', 'string'],
        ]);

        $user = User::where('email', $validated['email'])->first();

        if (! $user || ! Hash::check($validated['password'], $user->password)) {
            return $this->errorResponse('بيانات الدخول غير صحيحة', null, 422);
        }

        if ($user->status !== 'active') {
            return $this->errorResponse('هذا الحساب غير نشط حاليًا', null, 403);
        }

        $user->forceFill([
            'last_login_at' => now(),
        ])->save();

        $token = $user->createToken('mobile-app')->plainTextToken;

        return $this->successResponse([
            'token' => $token,
            'user' => $user->load('profile'),
        ], 'تم تسجيل الدخول بنجاح');
    }

    public function me(Request $request)
    {
        $user = $request->user()->load([
            'profile.level',
            'roles',
            'badges',
        ]);

        $profile = $user->profile;
        $points = $profile?->points ?? 0;
        $currentLevel = $this->currentLevelForPoints($points, $profile?->level);
        $nextLevel = $this->nextLevelForPoints($points);
        $roleKey = $this->roleKeyForUser($user);
        $roleLabel = $this->roleLabelForUser($user);

        $badgesCount = $user->badges()->count();

        $lessonsCount = $user->lessonCompletions()
            ->distinct()
            ->count('lesson_id');

        $coursesCount = $user->courseEnrollments()->count();

        $completedTasksCount = $user->userTasks()
            ->where('status', 'completed')
            ->count();

        return $this->successResponse([
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'phone' => $user->phone,
                'account_type' => $user->account_type,
                'status' => $user->status,
                'roles' => $user->roles,
                'role' => $roleLabel,
                'role_key' => $roleKey,
                'profile' => [
                    'id' => $profile?->id,
                    'display_name' => $profile?->display_name ?? $user->name,
                    'bio' => $profile?->bio,
                    'country' => $profile?->country,
                    'city' => $profile?->city,
                    'language' => $profile?->language ?? 'ar',
                    'points' => $points,
                    'total_points' => $points,
                    'avatar' => $profile?->avatar,
                    'role' => $roleLabel,
                    'role_key' => $roleKey,
                    'current_level' => $this->formatLevel($currentLevel),
                    'next_level' => $this->formatLevel($nextLevel),
                    'points_to_next_level' => $nextLevel
                        ? max(0, $nextLevel->required_points - $points)
                        : 0,
                    'streak_days' => $profile?->streak_days ?? 0,
                    'last_activity_date' => $profile?->last_activity_date?->toDateString(),
                ],
            ],
            'badges_count' => $badgesCount,
            'lessons_count' => $lessonsCount,
            'completed_lessons_count' => $lessonsCount,
            'courses_count' => $coursesCount,
            'completed_tasks_count' => $completedTasksCount,
            'points' => $points,
            'total_points' => $points,
            'current_level' => $this->formatLevel($currentLevel),
        ], 'تم جلب بيانات المستخدم بنجاح');
    }

    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()?->delete();

        return $this->successResponse(null, 'تم تسجيل الخروج بنجاح');
    }

    public function forgotPassword(Request $request)
    {
        $validated = $request->validate([
            'email' => ['required', 'email', 'exists:users,email'],
        ]);

        $status = Password::sendResetLink([
            'email' => $validated['email'],
        ]);

        if ($status !== Password::RESET_LINK_SENT) {
            return $this->errorResponse('تعذر إرسال رابط استعادة كلمة المرور', [
                'email' => __($status),
            ], 422);
        }

        return $this->successResponse(null, 'تم إرسال رابط استعادة كلمة المرور');
    }

    public function resetPassword(Request $request)
    {
        $validated = $request->validate([
            'token' => ['required', 'string'],
            'email' => ['required', 'email', 'exists:users,email'],
            'password' => ['required', 'confirmed', PasswordRule::min(8)],
        ]);

        $status = Password::reset(
            $validated,
            function (User $user, string $password) {
                $user->forceFill([
                    'password' => Hash::make($password),
                    'remember_token' => Str::random(60),
                ])->save();

                event(new PasswordReset($user));
            }
        );

        if ($status !== Password::PASSWORD_RESET) {
            return $this->errorResponse('تعذر تغيير كلمة المرور', [
                'email' => __($status),
            ], 422);
        }

        return $this->successResponse(null, 'تم تغيير كلمة المرور بنجاح');
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

    private function roleKeyForUser(User $user): string
    {
        $roleName = $user->roles?->pluck('name')->first();

        return $roleName
            ?? $user->account_type
            ?? 'user';
    }

    private function roleLabelForUser(User $user): string
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

    private function roleNameForAccountType(string $accountType): string
    {
        return match ($accountType) {
            'user' => 'student',
            default => $accountType,
        };
    }
}