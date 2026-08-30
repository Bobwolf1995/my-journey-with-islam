<?php

namespace Database\Seeders;

use App\Models\Level;
use Illuminate\Database\Seeder;

class LevelSeeder extends Seeder
{
    public function run(): void
    {
        $levels = [
            [
                'name_ar' => 'طالب علم',
                'slug' => 'student-of-knowledge',
                'description_ar' => 'بداية الرحلة وبناء الأساسيات خطوة بخطوة.',
                'order' => 1,
                'required_points' => 0,
                'icon' => 'seedling',
                'color' => '#0F766E',
            ],
            [
                'name_ar' => 'متعلم نشط',
                'slug' => 'active-learner',
                'description_ar' => 'مرحلة الاستمرار في التعلم وإكمال المهام اليومية.',
                'order' => 2,
                'required_points' => 300,
                'icon' => 'book-open',
                'color' => '#0E7490',
            ],
            [
                'name_ar' => 'داعية مبتدئ',
                'slug' => 'beginner-guide',
                'description_ar' => 'مرحلة مشاركة الخير ومساعدة الآخرين بمحتوى موثوق.',
                'order' => 3,
                'required_points' => 800,
                'icon' => 'heart-handshake',
                'color' => '#B45309',
            ],
            [
                'name_ar' => 'مرشد مؤثر',
                'slug' => 'impact-mentor',
                'description_ar' => 'مرحلة التأثير الإيجابي والمتابعة مع المتعلمين.',
                'order' => 4,
                'required_points' => 1500,
                'icon' => 'badge-check',
                'color' => '#115E59',
            ],
        ];

        foreach ($levels as $level) {
            Level::updateOrCreate(
                ['slug' => $level['slug']],
                $level
            );
        }
    }
}