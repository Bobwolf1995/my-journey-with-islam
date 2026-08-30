<?php

namespace Database\Seeders;

use App\Models\Badge;
use Illuminate\Database\Seeder;

class BadgeSeeder extends Seeder
{
    public function run(): void
    {
        $badges = [
            [
                'name_ar' => 'بداية الرحلة',
                'slug' => 'journey-started',
                'description_ar' => 'تمنح عند إنشاء الحساب والبدء في أول خطوة.',
                'icon' => 'sparkles',
                'color' => '#0F766E',
                'category' => 'learning',
                'required_points' => 0,
            ],
            [
                'name_ar' => 'أول درس',
                'slug' => 'first-lesson',
                'description_ar' => 'تمنح عند إكمال أول درس في التطبيق.',
                'icon' => 'book-open-check',
                'color' => '#0E7490',
                'category' => 'learning',
                'required_points' => 25,
            ],
            [
                'name_ar' => 'طالب نشط',
                'slug' => 'active-student',
                'description_ar' => 'تمنح عند إكمال مجموعة من الدروس والمهام.',
                'icon' => 'badge-check',
                'color' => '#B45309',
                'category' => 'progress',
                'required_points' => 100,
            ],
            [
                'name_ar' => 'قارئ المكتبة',
                'slug' => 'library-reader',
                'description_ar' => 'تمنح عند قراءة محتوى من المكتبة الإسلامية.',
                'icon' => 'library',
                'color' => '#7C3AED',
                'category' => 'library',
                'required_points' => 150,
            ],
            [
                'name_ar' => 'ملتزم أسبوعيا',
                'slug' => 'weekly-committed',
                'description_ar' => 'تمنح عند الاستمرار في التعلم عدة أيام متتالية.',
                'icon' => 'calendar-check',
                'color' => '#15803D',
                'category' => 'progress',
                'required_points' => 250,
            ],
            [
                'name_ar' => 'مشارك الخير',
                'slug' => 'goodness-sharer',
                'description_ar' => 'تمنح عند مشاركة محتوى نافع مع الآخرين.',
                'icon' => 'share-2',
                'color' => '#BE123C',
                'category' => 'community',
                'required_points' => 350,
            ],
            [
                'name_ar' => 'صديق المرشد',
                'slug' => 'mentor-friend',
                'description_ar' => 'تمنح عند التواصل والمتابعة مع المرشد.',
                'icon' => 'messages-square',
                'color' => '#0369A1',
                'category' => 'mentorship',
                'required_points' => 450,
            ],
            [
                'name_ar' => 'سفير الرحمة',
                'slug' => 'mercy-ambassador',
                'description_ar' => 'تمنح لمن يساهم في بيئة تعلم رحيمة وآمنة.',
                'icon' => 'heart-handshake',
                'color' => '#115E59',
                'category' => 'community',
                'required_points' => 700,
            ],
        ];

        foreach ($badges as $badge) {
            Badge::updateOrCreate(
                ['slug' => $badge['slug']],
                $badge
            );
        }
    }
}