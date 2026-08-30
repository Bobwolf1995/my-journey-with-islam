<?php

namespace App\Http\Controllers\Api;

use App\Models\AiChatLog;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Str;
use Throwable;

class AiAssistantController extends Controller
{
    public function ask(Request $request)
    {
        $validated = $request->validate([
            'question' => ['required', 'string', 'max:2000'],
        ]);

        $question = trim($validated['question']);
        $category = $this->detectCategory($question);
        $needsSpecialist = $this->isSensitiveQuestion($question);

        $provider = 'local';
        $answer = null;
        $error = null;

        if ($needsSpecialist) {
            $answer = $this->specialistAnswer();
            $provider = 'safety_guard';
        } else {
            try {
                $answer = $this->askOpenAi($question);
                $provider = $answer ? 'openai' : 'local';
            } catch (Throwable $exception) {
                report($exception);
                $error = $exception->getMessage();
            }

            if (! $answer) {
                $answer = $this->localFallbackAnswer($question, $category);
            }
        }

        $suggestedAction = $needsSpecialist
            ? 'contact_mentor'
            : $this->suggestedActionForCategory($category);

        $logId = null;

        try {
            $log = AiChatLog::create([
                'user_id' => $request->user()?->id,
                'title_ar' => Str::limit($question, 80, ''),
                'question' => $question,
                'answer' => $answer,
                'category' => $needsSpecialist ? 'sensitive' : $category,
                'context' => [
                    'needs_specialist' => $needsSpecialist,
                    'suggested_action' => $suggestedAction,
                ],
                'metadata' => [
                    'provider' => $provider,
                    'source' => 'api',
                    'error' => $error,
                ],
            ]);

            $logId = $log->id;
        } catch (Throwable $exception) {
            report($exception);
        }

        return $this->successResponse([
            'answer' => $answer,
            'message' => $answer,
            'category' => $needsSpecialist ? 'sensitive' : $category,
            'needs_specialist' => $needsSpecialist,
            'suggested_action' => $suggestedAction,
            'suggestions' => $this->suggestionsForCategory($category, $needsSpecialist),
            'provider' => $provider,
            'log_id' => $logId,
        ], 'تمت معالجة السؤال بنجاح');
    }

    private function askOpenAi(string $question): ?string
    {
        $apiKey = config('services.openai.api_key');

        if (! $apiKey) {
            return null;
        }

        $model = config('services.openai.model', 'gpt-4.1-mini');

        $response = Http::withToken($apiKey)
            ->timeout(30)
            ->acceptJson()
            ->post('https://api.openai.com/v1/chat/completions', [
                'model' => $model,
                'temperature' => 0.5,
                'max_tokens' => 700,
                'messages' => [
                    [
                        'role' => 'system',
                        'content' => implode("\n", [
                            'أنت مساعد ذكي داخل تطبيق "رحلتي مع الإسلام".',
                            'أجب بالعربية بلغة بسيطة وواضحة ومطمئنة.',
                            'أجب على الأسئلة العامة والتعليمية والحياتية العادية.',
                            'لا تصدر فتاوى ولا أحكام حلال/حرام ولا أحكام طلاق أو ميراث أو معاملات مالية شرعية.',
                            'إذا طلب المستخدم حكمًا شرعيًا خاصًا فقل له بلطف إن هذا يحتاج مرشدًا أو مختصًا موثوقًا.',
                            'اجعل الإجابة مختصرة ومفيدة، من فقرتين إلى أربع فقرات كحد أقصى.',
                        ]),
                    ],
                    [
                        'role' => 'user',
                        'content' => $question,
                    ],
                ],
            ]);

        if (! $response->successful()) {
            return null;
        }

        $content = $response->json('choices.0.message.content');

        if (! is_string($content) || trim($content) === '') {
            return null;
        }

        return trim($content);
    }

    private function localFallbackAnswer(string $question, string $category): string
    {
        return match ($category) {
            'prayer' => 'الصلاة تُبنى بالتدرّج والثبات. ابدأ بالمحافظة على الفريضة في وقتها، ثم تعلّم شروط الصلاة وأركانها خطوة خطوة. داخل التطبيق يمكنك البدء بدورة تعلم الصلاة لأنها أنسب نقطة لهذا السؤال.',

            'quran' => 'أفضل بداية مع القرآن أن تجعل لك وردًا صغيرًا ثابتًا، حتى لو خمس آيات يوميًا. اقرأ بتأنٍ، واستمع لتلاوة صحيحة، ثم اختر معنى واحدًا تطبقه في يومك.',

            'learning' => 'أفضل طريقة للتعلم هي أن تختار مسارًا واحدًا وتلتزم به. شاهد درسًا قصيرًا، اكتب خلاصة من سطرين، ثم طبّق نقطة واحدة في يومك.',

            'motivation' => 'الشعور بالفتور طبيعي، والمهم ألا يتحول إلى انقطاع. خفف المطلوب بدل أن تتركه بالكامل: خطوة صغيرة ثابتة أفضل من خطة كبيرة تنقطع.',

            default => 'أفهم سؤالك. أستطيع مساعدتك بخطوة عامة: حدّد ما تريد الوصول إليه، ثم ابدأ بخطوة صغيرة وواضحة اليوم. وإذا أردت، اكتب لي تفاصيل أكثر وسأرتّب لك الفكرة بطريقة أسهل.',
        };
    }

    private function specialistAnswer(): string
    {
        return 'هذا السؤال يحتاج إلى مرشد أو مختص موثوق، ولا يصح أن أعطيك حكمًا مباشرًا هنا. يمكنك إرسال السؤال للمرشد مع تفاصيل الحالة كاملة حتى تحصل على توجيه مناسب وآمن.';
    }

    private function detectCategory(string $question): string
    {
        $q = Str::lower($question);

        if (Str::contains($q, ['صلاة', 'الصلاة', 'اصلي', 'أصلي', 'ركوع', 'سجود', 'الفاتحة', 'تشهد'])) {
            return 'prayer';
        }

        if (Str::contains($q, ['قرآن', 'القرآن', 'سورة', 'آية', 'تلاوة', 'حفظ'])) {
            return 'quran';
        }

        if (Str::contains($q, ['أتعلم', 'اتعلم', 'تعلم', 'دورة', 'درس', 'من أين أبدأ', 'ابدأ'])) {
            return 'learning';
        }

        if (Str::contains($q, ['فتور', 'كسل', 'تعب', 'قلق', 'حيرة', 'ضعف', 'محبط', 'مقصر'])) {
            return 'motivation';
        }

        return 'general';
    }

    private function suggestionsForCategory(string $category, bool $needsSpecialist): array
    {
        if ($needsSpecialist) {
            return [
                'تواصل مع المرشد',
                'اكتب تفاصيل الحالة بوضوح',
                'لا تعتمد على جواب عام في المسائل الخاصة',
            ];
        }

        return match ($category) {
            'prayer' => ['ابدأ بدورة تعلم الصلاة', 'راجع شروط الصلاة', 'طبّق درسًا واحدًا اليوم'],
            'quran' => ['ابدأ بخمس آيات يوميًا', 'استمع لتلاوة صحيحة', 'اكتب معنى واحدًا من الآيات'],
            'learning' => ['اختر دورة واحدة', 'شاهد درسًا قصيرًا', 'اكتب خلاصة من سطرين'],
            'motivation' => ['خفف المطلوب ولا تنقطع', 'ابدأ بخطوة صغيرة', 'تابع مهمة يومية واحدة'],
            default => ['اكتب تفاصيل أكثر', 'حدّد هدفك', 'ابدأ بخطوة صغيرة'],
        };
    }

    private function suggestedActionForCategory(string $category): string
    {
        return match ($category) {
            'prayer', 'learning' => 'open_courses',
            'quran' => 'open_library',
            'motivation' => 'open_tasks',
            default => 'continue_learning',
        };
    }

    private function isSensitiveQuestion(string $question): bool
    {
        $keywords = [
            'فتوى',
            'أفتني',
            'افتي',
            'حلال',
            'حرام',
            'يجوز',
            'لا يجوز',
            'طلاق',
            'ميراث',
            'زواج',
            'ربا',
            'يمين',
            'كفارة',
            'حيض',
            'نفاس',
            'عدة',
            'وصية',
            'تكفير',
        ];

        return Str::contains($question, $keywords);
    }
}