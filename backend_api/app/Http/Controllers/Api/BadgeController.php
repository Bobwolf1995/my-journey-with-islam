<?php

namespace App\Http\Controllers\Api;

use App\Models\Badge;
use App\Models\Level;
use Illuminate\Http\Request;

class BadgeController extends Controller
{
    public function myBadges(Request $request)
    {
        $user = $request->user()->load('profile');
        $points = $user->profile?->points ?? 0;

        $this->awardEligibleBadges($user, $points);

        $badges = $user
            ->badges()
            ->latest('user_badges.created_at')
            ->get()
            ->map(function (Badge $badge) {
                $badge->setAttribute('is_awarded', true);
                $badge->setAttribute('awarded_at', $badge->pivot?->awarded_at);
                $badge->setAttribute('title', $badge->name_ar);

                return $badge;
            })
            ->values();

        return $this->successResponse($badges, 'تم جلب الأوسمة بنجاح');
    }

    public function levels()
    {
        $levels = Level::query()
            ->where('is_active', true)
            ->orderBy('order')
            ->get();

        return $this->successResponse($levels, 'تم جلب الرتب بنجاح');
    }

    private function awardEligibleBadges($user, int $points): void
    {
        $eligibleBadges = Badge::query()
            ->where('is_active', true)
            ->where('required_points', '<=', $points)
            ->orderBy('required_points')
            ->get();

        if ($eligibleBadges->isEmpty()) {
            return;
        }

        $existingBadgeIds = $user
            ->badges()
            ->pluck('badges.id')
            ->map(fn ($badgeId) => (int) $badgeId)
            ->all();

        $badgesToAttach = [];

        foreach ($eligibleBadges as $badge) {
            if (in_array((int) $badge->id, $existingBadgeIds, true)) {
                continue;
            }

            $badgesToAttach[$badge->id] = [
                'awarded_at' => now(),
                'created_at' => now(),
                'updated_at' => now(),
            ];
        }

        if ($badgesToAttach === []) {
            return;
        }

        $user->badges()->attach($badgesToAttach);
    }
}