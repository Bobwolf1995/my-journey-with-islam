<?php

namespace Database\Seeders;

use App\Models\CommunityGroup;
use App\Models\CommunityPost;
use App\Models\Course;
use App\Models\CourseSection;
use App\Models\LearningPath;
use App\Models\Lesson;
use App\Models\LibraryCategory;
use App\Models\LibraryItem;
use App\Models\Mentor;
use App\Models\MentorStudent;
use App\Models\Notification;
use App\Models\Profile;
use App\Models\Task;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use App\Models\LessonContent;
use App\Models\Quiz;
use App\Models\QuizOption;
use App\Models\QuizQuestion;

class DemoContentSeeder extends Seeder
{
    public function run(): void
    {
        $admin = User::updateOrCreate(
            ['email' => 'admin@rihlati.test'],
            [
                'name' => 'مدير المنصة',
                'phone' => '+201000000001',
                'password' => Hash::make('password'),
                'account_type' => 'admin',
                'status' => 'active',
                'email_verified_at' => now(),
            ]
        );

        $student = User::updateOrCreate(
            ['email' => 'ahmad@rihlati.test'],
            [
                'name' => 'أحمد محمد',
                'phone' => '+201000000002',
                'password' => Hash::make('password'),
                'account_type' => 'user',
                'status' => 'active',
                'email_verified_at' => now(),
            ]
        );

        $mentorUser = User::updateOrCreate(
            ['email' => 'mentor@rihlati.test'],
            [
                'name' => 'محمد سعيد',
                'phone' => '+201000000003',
                'password' => Hash::make('password'),
                'account_type' => 'mentor',
                'status' => 'active',
                'email_verified_at' => now(),
            ]
        );

        if (method_exists($admin, 'assignRole')) {
            $admin->assignRole('admin');
            $student->assignRole('student');
            $mentorUser->assignRole('mentor');
        }

        Profile::updateOrCreate(
            ['user_id' => $student->id],
            [
                'display_name' => 'أحمد محمد',
                'bio' => 'طالب علم في بداية رحلة التعلم.',
                'country' => 'مصر',
                'city' => 'القاهرة',
                'language' => 'ar',
                'points' => 650,
                'current_level_id' => 2,
                'avatar' => null,
            ]
        );

        Profile::updateOrCreate(
            ['user_id' => $mentorUser->id],
            [
                'display_name' => 'محمد سعيد',
                'bio' => 'مرشد يساعد المتعلمين الجدد خطوة بخطوة.',
                'country' => 'مصر',
                'city' => 'الإسكندرية',
                'language' => 'ar',
                'points' => 1200,
                'current_level_id' => 3,
                'avatar' => null,
            ]
        );

        $mentor = Mentor::updateOrCreate(
            ['user_id' => $mentorUser->id],
            [
                'specialization' => 'إرشاد المسلمين الجدد',
                'bio' => 'متخصص في متابعة المسلمين الجدد والإجابة عن أسئلتهم اليومية بلطف ووضوح.',
                'is_available' => true,
                'rating' => 4.80,
            ]
        );

        MentorStudent::updateOrCreate(
            [
                'mentor_id' => $mentor->id,
                'student_id' => $student->id,
            ],
            [
                'status' => 'active',
                'assigned_at' => now(),
            ]
        );

        $path = LearningPath::updateOrCreate(
            ['slug' => 'basic-islam-path'],
            [
                'name_ar' => 'المسار الأساسي',
                'description_ar' => 'مسار تعليمي مبسط يبدأ بأركان الإسلام والإيمان والعبادات اليومية.',
                'icon' => 'book-open',
                'color' => '#0F766E',
                'order' => 1,
                'is_active' => true,
            ]
        );

        $courses = [
            [
                'slug' => 'pillars-of-islam',
                'title_ar' => 'أركان الإسلام',
                'description_ar' => 'تعلم أركان الإسلام الخمسة بأسلوب واضح ومناسب للمبتدئين.',
                'short_description_ar' => 'مدخل مبسط إلى أركان الإسلام.',
                'level' => 'beginner',
                'order' => 1,
                'is_featured' => true,
                'section_title_ar' => 'المدخل إلى الإسلام',
                'section_description_ar' => 'دروس تمهيدية لفهم أساسيات الدين.',
                'lessons' => [
                    [
                        'title_ar' => 'ما معنى الإسلام؟',
                        'slug' => 'what-is-islam',
                        'content_ar' => 'الإسلام هو الاستسلام لله تعالى بالتوحيد والانقياد له بالطاعة والبراءة من الشرك.',
                        'duration_minutes' => 15,
                        'points' => 25,
                    ],
                    [
                        'title_ar' => 'الشهادتان',
                        'slug' => 'two-testimonies',
                        'content_ar' => 'الشهادتان هما أصل الدخول في الإسلام ومعناهما توحيد الله واتباع رسوله صلى الله عليه وسلم.',
                        'duration_minutes' => 15,
                        'points' => 25,
                    ],
                    [
                        'title_ar' => 'الصلاة',
                        'slug' => 'prayer-basics',
                        'content_ar' => 'الصلاة صلة بين العبد وربه، وهي عمود الدين وأعظم العبادات العملية.',
                        'duration_minutes' => 15,
                        'points' => 25,
                    ],
                    [
                        'title_ar' => 'الزكاة والصيام والحج',
                        'slug' => 'zakat-fasting-hajj',
                        'content_ar' => 'هذه العبادات تبني في المسلم الرحمة والانضباط والتجرد لله تعالى.',
                        'duration_minutes' => 15,
                        'points' => 25,
                    ],
                ],
            ],
            [
                'slug' => 'pillars-of-faith',
                'title_ar' => 'أركان الإيمان',
                'description_ar' => 'تعرف على أصول الإيمان الستة بطريقة هادئة ومناسبة للبدايات.',
                'short_description_ar' => 'شرح مبسط لأركان الإيمان.',
                'level' => 'beginner',
                'order' => 2,
                'is_featured' => true,
                'section_title_ar' => 'أساسيات الإيمان',
                'section_description_ar' => 'مدخل إلى أصول الاعتقاد التي يقوم عليها قلب المسلم.',
                'lessons' => [
                    [
                        'title_ar' => 'الإيمان بالله',
                        'slug' => 'faith-in-allah',
                        'content_ar' => 'الإيمان بالله هو أصل الإيمان، ويتضمن معرفة الله تعالى وتوحيده ومحبته وتعظيمه.',
                        'duration_minutes' => 18,
                        'points' => 30,
                    ],
                    [
                        'title_ar' => 'الإيمان بالملائكة والكتب',
                        'slug' => 'faith-in-angels-and-books',
                        'content_ar' => 'يؤمن المسلم بالملائكة الكرام وبالكتب التي أنزلها الله لهداية الناس.',
                        'duration_minutes' => 16,
                        'points' => 25,
                    ],
                    [
                        'title_ar' => 'الإيمان بالرسل واليوم الآخر',
                        'slug' => 'faith-in-messengers-and-last-day',
                        'content_ar' => 'أرسل الله الرسل مبشرين ومنذرين، واليوم الآخر يذكر المسلم بالمسؤولية والرجاء.',
                        'duration_minutes' => 18,
                        'points' => 30,
                    ],
                    [
                        'title_ar' => 'الإيمان بالقدر',
                        'slug' => 'faith-in-qadar',
                        'content_ar' => 'الإيمان بالقدر يعلّم المسلم الرضا والعمل وحسن الظن بالله تعالى.',
                        'duration_minutes' => 14,
                        'points' => 25,
                    ],
                ],
            ],
            [
                'slug' => 'learn-prayer',
                'title_ar' => 'تعلم الصلاة',
                'description_ar' => 'دورة عملية مبسطة لفهم الصلاة والاستعداد لها وأدائها بخشوع.',
                'short_description_ar' => 'خطوات الصلاة للمبتدئين.',
                'level' => 'beginner',
                'order' => 3,
                'is_featured' => true,
                'section_title_ar' => 'الصلاة خطوة بخطوة',
                'section_description_ar' => 'تعلم الطهارة وأوقات الصلاة وطريقة الأداء.',
                'lessons' => [
                    [
                        'title_ar' => 'الطهارة والوضوء',
                        'slug' => 'purification-and-wudu',
                        'content_ar' => 'الطهارة مفتاح الصلاة، والوضوء عبادة يتقرب بها المسلم إلى الله قبل الوقوف بين يديه.',
                        'duration_minutes' => 18,
                        'points' => 30,
                    ],
                    [
                        'title_ar' => 'أوقات الصلاة',
                        'slug' => 'prayer-times-intro',
                        'content_ar' => 'للصلاة أوقات محددة، والمحافظة عليها من أعظم أسباب الثبات والطمأنينة.',
                        'duration_minutes' => 12,
                        'points' => 20,
                    ],
                    [
                        'title_ar' => 'كيفية أداء الصلاة',
                        'slug' => 'how-to-pray-step-by-step',
                        'content_ar' => 'يتعلم المسلم أركان الصلاة من التكبير إلى التسليم مع فهم المعاني الأساسية.',
                        'duration_minutes' => 22,
                        'points' => 35,
                    ],
                    [
                        'title_ar' => 'الخشوع في الصلاة',
                        'slug' => 'khushu-in-prayer',
                        'content_ar' => 'الخشوع حضور القلب بين يدي الله، ويزداد بمعرفة ما نقول ونفعل في الصلاة.',
                        'duration_minutes' => 14,
                        'points' => 25,
                    ],
                ],
            ],
            [
                'slug' => 'quran-for-beginners',
                'title_ar' => 'القرآن للمبتدئين',
                'description_ar' => 'مدخل لطيف للتعامل مع القرآن قراءة وفهمًا وتدبرًا.',
                'short_description_ar' => 'ابدأ علاقتك بالقرآن.',
                'level' => 'beginner',
                'order' => 4,
                'is_featured' => false,
                'section_title_ar' => 'بداية مع القرآن',
                'section_description_ar' => 'دروس قصيرة تساعد على فهم مكانة القرآن وبداية القراءة.',
                'lessons' => [
                    [
                        'title_ar' => 'ما هو القرآن؟',
                        'slug' => 'what-is-quran',
                        'content_ar' => 'القرآن كلام الله تعالى، أنزله هداية ورحمة ونورًا للناس.',
                        'duration_minutes' => 12,
                        'points' => 20,
                    ],
                    [
                        'title_ar' => 'سورة الفاتحة ومعانيها',
                        'slug' => 'surah-al-fatiha-meanings',
                        'content_ar' => 'الفاتحة أعظم سورة في القرآن، وفيها الثناء على الله وطلب الهداية.',
                        'duration_minutes' => 18,
                        'points' => 30,
                    ],
                    [
                        'title_ar' => 'آداب قراءة القرآن',
                        'slug' => 'quran-reading-manners',
                        'content_ar' => 'من آداب قراءة القرآن الطهارة والإنصات والتدبر والعمل بما نتعلم.',
                        'duration_minutes' => 14,
                        'points' => 25,
                    ],
                    [
                        'title_ar' => 'خطة يومية بسيطة للقراءة',
                        'slug' => 'simple-daily-quran-plan',
                        'content_ar' => 'الاستمرار ولو بآيات قليلة كل يوم يفتح بابًا عظيمًا للطمأنينة والفهم.',
                        'duration_minutes' => 10,
                        'points' => 20,
                    ],
                ],
            ],
            [
                'slug' => 'islamic-manners',
                'title_ar' => 'الأخلاق والآداب الإسلامية',
                'description_ar' => 'تعلم الأخلاق اليومية التي تظهر جمال الإسلام في التعامل مع النفس والناس.',
                'short_description_ar' => 'أخلاق المسلم في الحياة اليومية.',
                'level' => 'beginner',
                'order' => 5,
                'is_featured' => false,
                'section_title_ar' => 'أخلاق المسلم',
                'section_description_ar' => 'نماذج عملية من الأخلاق والآداب التي يحتاجها المسلم كل يوم.',
                'lessons' => [
                    [
                        'title_ar' => 'الصدق والأمانة',
                        'slug' => 'truthfulness-and-trust',
                        'content_ar' => 'الصدق والأمانة من أعظم أخلاق المسلم، وهما أساس الثقة في القول والعمل.',
                        'duration_minutes' => 13,
                        'points' => 20,
                    ],
                    [
                        'title_ar' => 'بر الوالدين وصلة الرحم',
                        'slug' => 'parents-and-family-ties',
                        'content_ar' => 'يدعو الإسلام إلى الإحسان للوالدين وصلة الرحم بالكلمة الطيبة والعمل الصالح.',
                        'duration_minutes' => 15,
                        'points' => 25,
                    ],
                    [
                        'title_ar' => 'آداب الكلام',
                        'slug' => 'manners-of-speech',
                        'content_ar' => 'الكلمة الطيبة صدقة، ومن حسن إسلام المرء أن يحفظ لسانه ويختار ألفاظه.',
                        'duration_minutes' => 12,
                        'points' => 20,
                    ],
                    [
                        'title_ar' => 'الإحسان إلى الجار والناس',
                        'slug' => 'kindness-to-neighbors-and-people',
                        'content_ar' => 'الإحسان إلى الجار والناس صورة عملية من رحمة الإسلام وحسن الخلق.',
                        'duration_minutes' => 14,
                        'points' => 25,
                    ],
                ],
            ],
        ];

        foreach ($courses as $courseData) {
            $lessonCount = count($courseData['lessons']);
            $durationMinutes = collect($courseData['lessons'])->sum('duration_minutes');

            $course = Course::updateOrCreate(
                ['slug' => $courseData['slug']],
                [
                    'learning_path_id' => $path->id,
                    'title_ar' => $courseData['title_ar'],
                    'description_ar' => $courseData['description_ar'],
                    'short_description_ar' => $courseData['short_description_ar'],
                    'cover_image' => null,
                    'price' => 0,
                    'is_free' => true,
                    'level' => $courseData['level'],
                    'duration_minutes' => $durationMinutes,
                    'lessons_count' => $lessonCount,
                    'order' => $courseData['order'],
                    'is_featured' => $courseData['is_featured'],
                    'is_published' => true,
                    'published_at' => now(),
                ]
            );

            $section = CourseSection::updateOrCreate(
                [
                    'course_id' => $course->id,
                    'title_ar' => $courseData['section_title_ar'],
                ],
                [
                    'description_ar' => $courseData['section_description_ar'],
                    'order' => 1,
                    'is_active' => true,
                ]
            );

            foreach ($courseData['lessons'] as $index => $lessonData) {
                Lesson::updateOrCreate(
                    ['slug' => $lessonData['slug']],
                    [
                        'course_id' => $course->id,
                        'course_section_id' => $section->id,
                        'title_ar' => $lessonData['title_ar'],
                        'content_ar' => $lessonData['content_ar'],
                        'lesson_type' => 'text',
                        'video_url' => null,
                        'audio_url' => null,
                        'file_url' => null,
                        'duration_minutes' => $lessonData['duration_minutes'],
                        'points' => $lessonData['points'],
                        'order' => $index + 1,
                        'is_free' => true,
                        'is_published' => true,
                    ]
                );
            }
                   
        

        $starterLesson = Lesson::where('slug', 'what-is-islam')->first();

        if ($starterLesson) {
            $lessonContents = [
                [
                    'type' => 'subtitle',
                    'title_ar' => 'مدخل إلى معنى الإسلام',
                    'content_ar' => 'قبل الدخول في تفاصيل الأركان، نحتاج أن نفهم المعنى العام للإسلام.',
                    'order' => 1,
                    'meta' => null,
                ],
                [
                    'type' => 'paragraph',
                    'title_ar' => null,
                    'content_ar' => 'الإسلام هو الاستسلام لله تعالى بالتوحيد، والانقياد له بالطاعة، والابتعاد عما يخالف أمره. وهو طريق يربط بين الإيمان والعمل والأخلاق.',
                    'order' => 2,
                    'meta' => null,
                ],
                [
                    'type' => 'bullet_list',
                    'title_ar' => 'نقاط أساسية',
                    'content_ar' => "الإسلام يقوم على توحيد الله.\nالإسلام يجمع بين الاعتقاد والعمل.\nأركان الإسلام هي الأساس العملي للمسلم.\nالتعلم يكون خطوة خطوة دون استعجال.",
                    'order' => 3,
                    'meta' => [
                        'items' => [
                            'الإسلام يقوم على توحيد الله.',
                            'الإسلام يجمع بين الاعتقاد والعمل.',
                            'أركان الإسلام هي الأساس العملي للمسلم.',
                            'التعلم يكون خطوة خطوة دون استعجال.',
                        ],
                    ],
                ],
                [
                    'type' => 'important_note',
                    'title_ar' => 'معلومة مهمة',
                    'content_ar' => 'فهم الإسلام لا يعني حفظ المعلومات فقط، بل تحويل المعرفة إلى عمل يومي بسيط ومستمر.',
                    'order' => 4,
                    'meta' => null,
                ],
                [
                    'type' => 'common_mistake',
                    'title_ar' => 'خطأ شائع',
                    'content_ar' => 'من الأخطاء الشائعة أن يظن المتعلم أنه يجب أن يعرف كل شيء دفعة واحدة. الصحيح أن يبدأ بالأساسيات ثم يتدرج.',
                    'order' => 5,
                    'meta' => null,
                ],
                [
                    'type' => 'summary',
                    'title_ar' => 'ملخص الدرس',
                    'content_ar' => 'الإسلام هو الاستسلام لله بالتوحيد والطاعة، وبداية الرحلة تكون بفهم المعنى العام ثم تعلم الأركان الأساسية بالتدرج.',
                    'order' => 6,
                    'meta' => null,
                ],
            ];

            foreach ($lessonContents as $content) {
                LessonContent::updateOrCreate(
                    [
                        'lesson_id' => $starterLesson->id,
                        'type' => $content['type'],
                        'order' => $content['order'],
                    ],
                    [
                        'title_ar' => $content['title_ar'],
                        'content_ar' => $content['content_ar'],
                        'media_path' => null,
                        'meta' => $content['meta'],
                        'is_active' => true,
                    ]
                );
            }

            $quiz = Quiz::updateOrCreate(
                ['lesson_id' => $starterLesson->id],
                [
                    'title_ar' => 'اختبار درس: ما معنى الإسلام؟',
                    'description_ar' => 'اختبار قصير للتأكد من فهم المعنى العام للإسلام.',
                    'passing_score' => 70,
                    'max_attempts' => null,
                    'is_active' => true,
                ]
            );

            $quizQuestions = [
                [
                    'question_ar' => 'ما المعنى العام للإسلام؟',
                    'explanation_ar' => 'الإسلام هو الاستسلام لله بالتوحيد والانقياد له بالطاعة.',
                    'order' => 1,
                    'options' => [
                        ['option_ar' => 'الاستسلام لله بالتوحيد والطاعة', 'is_correct' => true],
                        ['option_ar' => 'قراءة الكتب فقط', 'is_correct' => false],
                        ['option_ar' => 'معرفة التاريخ فقط', 'is_correct' => false],
                        ['option_ar' => 'ترك العمل والاكتفاء بالنية', 'is_correct' => false],
                    ],
                ],
                [
                    'question_ar' => 'ما أول أساس في فهم الإسلام؟',
                    'explanation_ar' => 'أول أساس هو توحيد الله تعالى وإفراده بالعبادة.',
                    'order' => 2,
                    'options' => [
                        ['option_ar' => 'توحيد الله', 'is_correct' => true],
                        ['option_ar' => 'كثرة الكلام', 'is_correct' => false],
                        ['option_ar' => 'حفظ أسماء الكتب', 'is_correct' => false],
                        ['option_ar' => 'البدء بالتفاصيل الصعبة', 'is_correct' => false],
                    ],
                ],
                [
                    'question_ar' => 'كيف يتعلم المسلم أساسيات دينه؟',
                    'explanation_ar' => 'الأفضل أن يتعلم بالتدرج خطوة خطوة دون استعجال.',
                    'order' => 3,
                    'options' => [
                        ['option_ar' => 'بالتدرج خطوة خطوة', 'is_correct' => true],
                        ['option_ar' => 'دفعة واحدة في يوم واحد', 'is_correct' => false],
                        ['option_ar' => 'بدون ترتيب', 'is_correct' => false],
                        ['option_ar' => 'بترك الأساسيات', 'is_correct' => false],
                    ],
                ],
                [
                    'question_ar' => 'أي عبارة تصف العلاقة بين العلم والعمل؟',
                    'explanation_ar' => 'المقصود من العلم أن يتحول إلى عمل وأخلاق وسلوك.',
                    'order' => 4,
                    'options' => [
                        ['option_ar' => 'العلم الصحيح يساعد على العمل الصحيح', 'is_correct' => true],
                        ['option_ar' => 'العلم لا علاقة له بالعمل', 'is_correct' => false],
                        ['option_ar' => 'العمل يكفي دون فهم', 'is_correct' => false],
                        ['option_ar' => 'الحفظ وحده هو الغاية', 'is_correct' => false],
                    ],
                ],
                [
                    'question_ar' => 'ما الخطأ الشائع عند بداية التعلم؟',
                    'explanation_ar' => 'من الخطأ أن يظن المتعلم أنه يجب أن يعرف كل شيء دفعة واحدة.',
                    'order' => 5,
                    'options' => [
                        ['option_ar' => 'محاولة معرفة كل شيء دفعة واحدة', 'is_correct' => true],
                        ['option_ar' => 'البدء بالأساسيات', 'is_correct' => false],
                        ['option_ar' => 'التعلم بتدرج', 'is_correct' => false],
                        ['option_ar' => 'السؤال عند عدم الفهم', 'is_correct' => false],
                    ],
                ],
            ];

            foreach ($quizQuestions as $questionData) {
                $question = QuizQuestion::updateOrCreate(
                    [
                        'quiz_id' => $quiz->id,
                        'order' => $questionData['order'],
                    ],
                    [
                        'question_ar' => $questionData['question_ar'],
                        'explanation_ar' => $questionData['explanation_ar'],
                        'points' => 1,
                        'is_active' => true,
                    ]
                );

                foreach ($questionData['options'] as $optionIndex => $optionData) {
                    QuizOption::updateOrCreate(
                        [
                            'quiz_question_id' => $question->id,
                            'order' => $optionIndex + 1,
                        ],
                        [
                            'option_ar' => $optionData['option_ar'],
                            'is_correct' => $optionData['is_correct'],
                        ]
                    );
                }
                       }
        }

        $tasks = [
            ['title_ar' => 'شاهد الدرس الرابع', 'points' => 15, 'type' => 'lesson'],
            ['title_ar' => 'أجب على الاختبار', 'points' => 20, 'type' => 'quiz'],
            ['title_ar' => 'اقرأ ملخص الدرس', 'points' => 10, 'type' => 'reading'],
            ['title_ar' => 'تواصل مع مرشدك', 'points' => 15, 'type' => 'mentor'],
            ['title_ar' => 'صلاة الفجر في وقتها', 'points' => 5, 'type' => 'habit'],
        ];

        foreach ($tasks as $index => $task) {
            Task::updateOrCreate(
                ['title_ar' => $task['title_ar']],
                [
                    'description_ar' => 'مهمة يومية تساعدك على الثبات والاستمرار.',
                    'type' => $task['type'],
                    'points' => $task['points'],
                    'order' => $index + 1,
                    'is_active' => true,
                ]
            );
        }

        $beginnerBooksCategory = LibraryCategory::updateOrCreate(
            ['slug' => 'beginner-books'],
            [
                'name_ar' => 'كتب للمبتدئين',
                'description_ar' => 'محتوى مختصر وموثوق للمسلمين الجدد.',
                'icon' => 'library',
                'color' => '#0F766E',
                'order' => 1,
                'is_active' => true,
            ]
        );

        $azkarCategory = LibraryCategory::updateOrCreate(
            ['slug' => 'azkar-and-dua'],
            [
                'name_ar' => 'أدعية وأذكار',
                'description_ar' => 'أذكار وأدعية يومية تساعد المسلم على الثبات والطمأنينة.',
                'icon' => 'heart',
                'color' => '#0E7490',
                'order' => 2,
                'is_active' => true,
            ]
        );

        $articlesCategory = LibraryCategory::updateOrCreate(
            ['slug' => 'short-articles'],
            [
                'name_ar' => 'مقالات قصيرة',
                'description_ar' => 'مقالات مبسطة تجيب عن أسئلة شائعة وتدعم بداية الرحلة.',
                'icon' => 'file-text',
                'color' => '#B45309',
                'order' => 3,
                'is_active' => true,
            ]
        );

        $beginnerGuideCategory = LibraryCategory::updateOrCreate(
            ['slug' => 'beginner-guide'],
            [
                'name_ar' => 'دليل البداية',
                'description_ar' => 'محتوى مختصر يساعد المستخدم على ترتيب خطواته الأولى',
                'icon' => 'map',
                'color' => '#0F766E',
                'order' => 4,
                'is_active' => true,
            ]
        );

        $libraryItems = [
            [
                'category_id' => $beginnerGuideCategory->id,
                'slug' => 'new-muslim-guide',
                'title_ar' => 'دليل المسلم الجديد',
                'description_ar' => 'دليل مختصر يساعد المسلم الجديد على فهم الخطوات الأولى بهدوء ووضوح.',
                'content_ar' => 'ابدأ بالتوحيد، ثم تعلم الصلاة تدريجيًا، واحرص على صحبة صالحة وسؤال أهل العلم عند الحاجة.',
                'type' => 'book',
                'is_featured' => true,
            ],
            [
                'category_id' => $beginnerGuideCategory->id,
                'slug' => 'pillars-of-islam-pdf',
                'title_ar' => 'أركان الإسلام PDF',
                'description_ar' => 'ملخص مبسط لأركان الإسلام الخمسة بصيغة مناسبة للقراءة السريعة.',
                'content_ar' => 'يتناول هذا الدليل الشهادتين والصلاة والزكاة والصيام والحج بصورة مختصرة ومناسبة للمبتدئين.',
                'type' => 'pdf',
                'is_featured' => true,
            ],
            [
                'category_id' => $beginnerGuideCategory->id,
                'slug' => 'how-to-start-prayer',
                'title_ar' => 'كيف تبدأ الصلاة',
                'description_ar' => 'خطوات عملية بسيطة للبدء في تعلم الصلاة دون ارتباك.',
                'content_ar' => 'ابدأ بمعرفة الوضوء وأوقات الصلاة، ثم تعلم الفاتحة والحركات الأساسية، ومع الوقت تكتمل التفاصيل.',
                'type' => 'book',
                'is_featured' => true,
            ],
            [
                'category_id' => $beginnerGuideCategory->id,
                'slug' => 'short-azkar-for-beginners',
                'title_ar' => 'أذكار مختصرة للمبتدئين',
                'description_ar' => 'مجموعة مختصرة من الأذكار اليومية السهلة للحفظ والمداومة.',
                'content_ar' => 'تبدأ الأذكار بكلمات يسيرة مثل الحمد لله، سبحان الله، لا إله إلا الله، والاستغفار والدعاء بما يحتاجه المسلم.',
                'type' => 'pdf',
                'is_featured' => false,
            ],
            [
                'category_id' => $beginnerGuideCategory->id,
                'slug' => 'starter-common-questions',
                'title_ar' => 'أسئلة البداية الشائعة',
                'description_ar' => 'إجابات قصيرة على أكثر الأسئلة التي تظهر في بداية الرحلة.',
                'content_ar' => 'يجمع هذا الدليل أسئلة حول الصلاة، والقراءة، والتدرج في التعلم، والتعامل مع العائلة والمجتمع.',
                'type' => 'book',
                'is_featured' => false,
            ],
            [
                'category_id' => $beginnerGuideCategory->id,
                'slug' => 'first-week-in-islam-plan',
                'title_ar' => 'خطة أول أسبوع في الإسلام',
                'description_ar' => 'خطة خفيفة لمدة أسبوع تساعد المستخدم على ترتيب بدايته خطوة بخطوة.',
                'content_ar' => 'اليوم الأول للتوحيد، الثاني للطهارة، الثالث للصلاة، الرابع للفاتحة، الخامس للأذكار، السادس للمراجعة، والسابع لوضع عادة ثابتة.',
                'type' => 'pdf',
                'is_featured' => false,
            ],
            [
                'category_id' => $beginnerBooksCategory->id,
                'slug' => 'islam-summary-book',
                'title_ar' => 'كتاب مبسط في الإسلام',
                'description_ar' => 'مقدمة سهلة في أهم معاني الإسلام وأصوله.',
                'content_ar' => 'هذا محتوى تجريبي يمكن استبداله لاحقا بمحتوى شرعي معتمد.',
                'type' => 'book',
                'is_featured' => true,
            ],
            [
                'category_id' => $beginnerBooksCategory->id,
                'slug' => 'short-prayer-guide',
                'title_ar' => 'دليل الصلاة المختصر',
                'description_ar' => 'شرح عملي مختصر يساعدك على تعلم الصلاة خطوة بخطوة.',
                'content_ar' => 'يتناول هذا الدليل الطهارة والوضوء وأركان الصلاة وأهم الأذكار داخل الصلاة.',
                'type' => 'book',
                'is_featured' => true,
            ],
            [
                'category_id' => $azkarCategory->id,
                'slug' => 'morning-evening-azkar',
                'title_ar' => 'أذكار الصباح والمساء',
                'description_ar' => 'مجموعة مختارة من الأذكار اليومية المناسبة للبداية.',
                'content_ar' => 'الأذكار اليومية تعين المسلم على ذكر الله وطمأنينة القلب وحفظ الوقت.',
                'type' => 'article',
                'is_featured' => true,
            ],
            [
                'category_id' => $beginnerBooksCategory->id,
                'slug' => 'meanings-of-al-fatiha',
                'title_ar' => 'معاني سورة الفاتحة',
                'description_ar' => 'شرح سهل لمعاني الفاتحة التي يكررها المسلم في كل صلاة.',
                'content_ar' => 'تجمع الفاتحة بين الثناء على الله وطلب الهداية والاستعانة به سبحانه.',
                'type' => 'article',
                'is_featured' => false,
            ],
            [
                'category_id' => $articlesCategory->id,
                'slug' => 'new-muslim-common-questions',
                'title_ar' => 'أسئلة شائعة للمسلمين الجدد',
                'description_ar' => 'إجابات موجزة على أسئلة تتكرر في بداية الطريق.',
                'content_ar' => 'تتناول هذه المادة أسئلة حول الصلاة والتعلم والتدرج والتعامل مع الأسرة والمجتمع.',
                'type' => 'article',
                'is_featured' => false,
            ],
            [
                'category_id' => $articlesCategory->id,
                'slug' => 'steadfastness-after-start',
                'title_ar' => 'الثبات بعد البداية',
                'description_ar' => 'خطوات بسيطة تساعدك على الاستمرار دون ضغط أو تشتت.',
                'content_ar' => 'الثبات يبدأ بخطوات صغيرة دائمة، وصحبة صالحة، وسؤال أهل العلم عند الحاجة.',
                'type' => 'article',
                'is_featured' => false,
            ],
            [
                'category_id' => $azkarCategory->id,
                'slug' => 'simple-daily-dua',
                'title_ar' => 'أدعية يومية مختصرة',
                'description_ar' => 'أدعية سهلة الحفظ تقال في اليوم والليلة.',
                'content_ar' => 'الدعاء صلة مباشرة بين العبد وربه، وهو باب للسكينة والرجاء وحسن التوكل.',
                'type' => 'article',
                'is_featured' => false,
            ],
        ];

        foreach ($libraryItems as $item) {
            LibraryItem::updateOrCreate(
                ['slug' => $item['slug']],
                [
                    'library_category_id' => $item['category_id'],
                    'title_ar' => $item['title_ar'],
                    'description_ar' => $item['description_ar'],
                    'content_ar' => $item['content_ar'],
                    'type' => $item['type'],
                    'cover_image' => null,
                    'file_url' => null,
                    'price' => 0,
                    'is_free' => true,
                    'is_featured' => $item['is_featured'],
                    'is_published' => true,
                    'published_at' => now(),
                ]
            );
        }

        $communityGroup = CommunityGroup::updateOrCreate(
            ['slug' => 'new-muslims'],
            [
                'name_ar' => 'مجتمع المسلمين الجدد',
                'description_ar' => 'مساحة آمنة للأسئلة والمشاركة والتشجيع.',
                'icon' => 'users',
                'color' => '#0F766E',
                'visibility' => 'public',
                'is_active' => true,
            ]
        );

        $communityMembers = [
            ['user_id' => $admin->id, 'role' => 'admin'],
            ['user_id' => $mentorUser->id, 'role' => 'moderator'],
            ['user_id' => $student->id, 'role' => 'member'],
        ];

        foreach ($communityMembers as $member) {
            DB::table('community_group_members')->updateOrInsert(
                [
                    'community_group_id' => $communityGroup->id,
                    'user_id' => $member['user_id'],
                ],
                [
                    'role' => $member['role'],
                    'joined_at' => now(),
                    'created_at' => now(),
                    'updated_at' => now(),
                ]
            );
        }

        $communityPosts = [
            [
                'title_ar' => 'أول خطوة في الرحلة',
                'content_ar' => 'بدأت اليوم بمراجعة درس أركان الإسلام، وأحببت بساطة الشرح وترتيب الخطوات.',
                'user_id' => $student->id,
                'likes_count' => 18,
                'comments_count' => 0,
            ],
            [
                'title_ar' => 'نصيحة للمداومة',
                'content_ar' => 'اجعل لك وقتًا ثابتًا كل يوم للتعلم ولو عشر دقائق، فالاستمرار يصنع فرقًا كبيرًا.',
                'user_id' => $mentorUser->id,
                'likes_count' => 12,
                'comments_count' => 0,
            ],
            [
                'title_ar' => 'سؤال عن ترتيب الدروس',
                'content_ar' => 'هل الأفضل أن أنهي مسار أركان الإسلام كاملًا قبل الانتقال إلى المكتبة؟',
                'user_id' => $admin->id,
                'likes_count' => 7,
                'comments_count' => 0,
            ],
        ];

        foreach ($communityPosts as $post) {
            CommunityPost::updateOrCreate(
                [
                    'community_group_id' => $communityGroup->id,
                    'title_ar' => $post['title_ar'],
                ],
                [
                    'user_id' => $post['user_id'],
                    'content_ar' => $post['content_ar'],
                    'status' => 'published',
                    'likes_count' => $post['likes_count'],
                    'comments_count' => $post['comments_count'],
                ]
            );
        }

        $notifications = [
            [
                'user_id' => null,
                'title_ar' => 'تم إضافة دورات جديدة',
                'body_ar' => 'يمكنك الآن متابعة دورات أركان الإيمان وتعلم الصلاة والقرآن للمبتدئين.',
                'type' => 'course',
                'data' => ['screen' => 'courses'],
            ],
            [
                'user_id' => $student->id,
                'title_ar' => 'درس جديد مناسب لك',
                'body_ar' => 'ابدأ درس الإيمان بالله ضمن دورة أركان الإيمان.',
                'type' => 'lesson',
                'data' => ['screen' => 'courses', 'course_slug' => 'pillars-of-faith'],
            ],
            [
                'user_id' => $student->id,
                'title_ar' => 'لا تنس مهمة اليوم',
                'body_ar' => 'أكمل مهمة اليوم واحصل على نقاط إضافية في رحلتك.',
                'type' => 'task',
                'data' => ['screen' => 'tasks'],
            ],
            [
                'user_id' => $student->id,
                'title_ar' => 'رسالة من المرشد',
                'body_ar' => 'مرشدك محمد سعيد جاهز لمساعدتك والإجابة عن أسئلتك.',
                'type' => 'mentor',
                'data' => ['screen' => 'chat'],
            ],
            [
                'user_id' => null,
                'title_ar' => 'محتوى جديد في المكتبة',
                'body_ar' => 'تمت إضافة أذكار ومقالات قصيرة لدعم بداية رحلتك.',
                'type' => 'library',
                'data' => ['screen' => 'library'],
            ],
        ];

        foreach ($notifications as $notification) {
            Notification::updateOrCreate(
                [
                    'user_id' => $notification['user_id'],
                    'title_ar' => $notification['title_ar'],
                    'type' => $notification['type'],
                ],
                [
                    'body_ar' => $notification['body_ar'],
                    'data' => $notification['data'],
                    'read_at' => null,
                ]
            );
        }
    }
    }
}