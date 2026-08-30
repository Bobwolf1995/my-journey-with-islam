<?php

namespace App\Http\Controllers\Api;

use App\Models\Conversation;
use App\Models\Message;
use App\Models\User;
use Illuminate\Http\Request;

class MessageController extends Controller
{
    public function conversations(Request $request)
    {
        $this->ensureDefaultConversation($request);

        $userId = $request->user()->id;

        $conversations = Conversation::query()
            ->whereHas('participants', function ($query) use ($userId) {
                $query->where('user_id', $userId);
            })
            ->with(['participants.user.profile', 'latestMessage.sender.profile'])
            ->latest('last_message_at')
            ->paginate(20);

        $conversations->getCollection()->transform(function (Conversation $conversation) use ($userId) {
            return $this->decorateConversationForUser($conversation, $userId);
        });

        return $this->successResponse($conversations, 'تم جلب المحادثات بنجاح');
    }

    public function createConversation(Request $request)
    {
        $validated = $request->validate([
            'type' => ['required', 'in:mentor,support,admin'],
            'title' => ['nullable', 'string', 'max:190'],
            'participant_ids' => ['required', 'array', 'min:1'],
            'participant_ids.*' => ['integer', 'exists:users,id'],
        ]);

        $conversation = Conversation::create([
            'type' => $validated['type'],
            'title' => $validated['title'] ?? null,
            'created_by' => $request->user()->id,
            'last_message_at' => now(),
        ]);

        $participantIds = collect($validated['participant_ids'])
            ->push($request->user()->id)
            ->unique()
            ->values();

        foreach ($participantIds as $userId) {
            $conversation->participants()->create([
                'user_id' => $userId,
                'last_read_at' => (int) $userId === (int) $request->user()->id ? now() : null,
            ]);
        }

        $conversation->load(['participants.user.profile', 'latestMessage.sender.profile']);

        return $this->successResponse(
            $this->decorateConversationForUser($conversation, $request->user()->id),
            'تم إنشاء المحادثة بنجاح',
            201
        );
    }

    public function messages(Request $request, Conversation $conversation)
    {
        if (! $this->isParticipant($request, $conversation)) {
            return $this->errorResponse('لا تملك صلاحية عرض هذه المحادثة', null, 403);
        }

        $userId = $request->user()->id;

        $conversation->messages()
            ->where('sender_id', '!=', $userId)
            ->where('is_read', false)
            ->update([
                'is_read' => true,
            ]);

        $conversation->participants()
            ->where('user_id', $userId)
            ->update([
                'last_read_at' => now(),
            ]);

        $messages = $conversation->messages()
            ->with(['sender.profile', 'attachments'])
            ->latest()
            ->paginate(30);

        $messages->getCollection()->transform(function (Message $message) use ($userId) {
            return $this->decorateMessageForUser($message, $userId);
        });

        return $this->successResponse($messages, 'تم جلب الرسائل بنجاح');
    }

    public function sendMessage(Request $request, Conversation $conversation)
    {
        if (! $this->isParticipant($request, $conversation)) {
            return $this->errorResponse('لا تملك صلاحية إرسال رسالة في هذه المحادثة', null, 403);
        }

        $validated = $request->validate([
            'body' => ['nullable', 'string', 'max:5000'],
            'text' => ['nullable', 'string', 'max:5000'],
            'message' => ['nullable', 'string', 'max:5000'],
            'content' => ['nullable', 'string', 'max:5000'],
            'message_type' => ['nullable', 'in:text,file,image,audio'],
        ]);

        $messageType = $validated['message_type'] ?? 'text';
        $body = $validated['body']
            ?? $validated['text']
            ?? $validated['message']
            ?? $validated['content']
            ?? null;

        if ($messageType === 'text' && trim((string) $body) === '') {
            return $this->errorResponse('نص الرسالة مطلوب', null, 422);
        }

        $message = $conversation->messages()->create([
            'sender_id' => $request->user()->id,
            'body' => $body,
            'message_type' => $messageType,
            'is_read' => false,
        ]);

        $conversation->forceFill([
            'last_message_at' => now(),
        ])->save();

        $conversation->participants()
            ->where('user_id', $request->user()->id)
            ->update([
                'last_read_at' => now(),
            ]);

        $message->load(['sender.profile', 'attachments']);

        return $this->successResponse(
            $this->decorateMessageForUser($message, $request->user()->id),
            'تم إرسال الرسالة بنجاح',
            201
        );
    }

    private function ensureDefaultConversation(Request $request): void
    {
        $hasConversation = Conversation::query()
            ->whereHas('participants', function ($query) use ($request) {
                $query->where('user_id', $request->user()->id);
            })
            ->exists();

        if ($hasConversation) {
            return;
        }

        $conversation = Conversation::create([
            'type' => 'mentor',
            'title' => 'المرشد',
            'created_by' => $request->user()->id,
            'last_message_at' => now(),
        ]);

        $participantIds = collect([
            $request->user()->id,
            $this->findDefaultMentorId($request->user()->id),
        ])->filter()->unique()->values();

        foreach ($participantIds as $userId) {
            $conversation->participants()->create([
                'user_id' => $userId,
                'last_read_at' => (int) $userId === (int) $request->user()->id ? now() : null,
            ]);
        }
    }

    private function findDefaultMentorId(int $currentUserId): ?int
    {
        return User::query()
            ->where('id', '!=', $currentUserId)
            ->whereIn('account_type', ['mentor', 'teacher', 'supervisor', 'admin'])
            ->orderBy('id')
            ->value('id');
    }

    private function isParticipant(Request $request, Conversation $conversation): bool
    {
        return $conversation->participants()
            ->where('user_id', $request->user()->id)
            ->exists();
    }

    private function decorateConversationForUser(Conversation $conversation, int $userId): Conversation
    {
        $otherParticipant = $conversation->participants
            ->first(function ($participant) use ($userId) {
                return (int) $participant->user_id !== $userId;
            });

        $otherUser = $otherParticipant?->user;
        $latestMessage = $conversation->latestMessage;

        $unreadCount = $conversation->messages()
            ->where('sender_id', '!=', $userId)
            ->where('is_read', false)
            ->count();

        $conversation->setAttribute('display_title', $conversation->title ?? $otherUser?->name ?? 'محادثة');
        $conversation->setAttribute('other_participant_id', $otherUser?->id);
        $conversation->setAttribute('other_participant_name', $otherUser?->profile?->display_name ?? $otherUser?->name);
        $conversation->setAttribute('other_participant_avatar', $otherUser?->profile?->avatar);
        $conversation->setAttribute('latest_message_text', $latestMessage?->body);
        $conversation->setAttribute('latest_message_type', $latestMessage?->message_type);
        $conversation->setAttribute('latest_message_at', $latestMessage?->created_at?->toISOString());
        $conversation->setAttribute('unread_count', $unreadCount);
        $conversation->setAttribute('has_unread', $unreadCount > 0);

        return $conversation;
    }

    private function decorateMessageForUser(Message $message, int $userId): Message
    {
        $senderName = $message->sender?->profile?->display_name
            ?? $message->sender?->name;

        $senderAvatar = $message->sender?->profile?->avatar;

        $message->setAttribute('text', $message->body);
        $message->setAttribute('content', $message->body);
        $message->setAttribute('message', $message->body);
        $message->setAttribute('type', $message->message_type);
        $message->setAttribute('sender_name', $senderName);
        $message->setAttribute('sender_avatar', $senderAvatar);
        $message->setAttribute('is_mine', (int) $message->sender_id === $userId);
        $message->setAttribute('sent_at', $message->created_at?->toISOString());

        return $message;
    }
}