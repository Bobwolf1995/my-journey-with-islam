<?php

namespace App\Filament\Widgets;

use App\Models\AiChatLog;
use App\Models\CommunityPost;
use App\Models\Course;
use App\Models\Lesson;
use App\Models\LibraryItem;
use App\Models\Notification;
use App\Models\Order;
use App\Models\Payment;
use App\Models\User;
use Filament\Widgets\StatsOverviewWidget;
use Filament\Widgets\StatsOverviewWidget\Stat;

class AdminStatsOverview extends StatsOverviewWidget
{
    protected ?string $heading = 'نظرة عامة على المنصة';

    protected int | array | null $columns = 3;

    protected function getStats(): array
    {
        $successfulPaymentsTotal = Payment::query()
            ->where('status', 'paid')
            ->sum('amount');

        return [
            Stat::make('عدد المستخدمين', User::query()->count())
                ->color('primary'),

            Stat::make('الدورات المنشورة', Course::query()->where('is_published', true)->count())
                ->color('success'),

            Stat::make('عدد الدروس', Lesson::query()->count())
                ->color('info'),

            Stat::make('عناصر المكتبة', LibraryItem::query()->count())
                ->color('warning'),

            Stat::make('منشورات المجتمع', CommunityPost::query()->count())
                ->color('primary'),

            Stat::make('عدد الطلبات', Order::query()->count())
                ->color('gray'),

            Stat::make('إجمالي المدفوعات الناجحة', number_format((float) $successfulPaymentsTotal, 2))
                ->description('للمدفوعات بحالة paid')
                ->color('success'),

            Stat::make('سجلات AI', AiChatLog::query()->count())
                ->color('info'),

            Stat::make('عدد الإشعارات', Notification::query()->count())
                ->color('warning'),
        ];
    }
}