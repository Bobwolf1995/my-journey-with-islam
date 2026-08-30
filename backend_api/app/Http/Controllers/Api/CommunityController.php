<?php

namespace App\Http\Controllers\Api;

use App\Models\CommunityComment;
use App\Models\CommunityGroup;
use App\Models\CommunityPost;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class CommunityController extends Controller
{
    public function groups(Request $request)
    {
        $userId = $request->user()->id;

        $groups = CommunityGroup::query()
            ->where('is_active', true)
            ->withCount(['members', 'posts'])
            ->latest()
            ->paginate(20);

        $groups->getCollection()->transform(function (CommunityGroup $group) use ($userId) {
            return $this->decorateGroupForUser($group, $userId);
        });

        return $this->successResponse($groups, 'تم جلب المجموعات بنجاح');
    }

    public function posts(Request $request)
    {
        $userId = $request->user()->id;

        $posts = CommunityPost::query()
            ->with([
                'user.profile',
                'group',
                'comments' => function ($query) {
                    $query->with('user.profile')->oldest();
                },
            ])
            ->withCount(['comments', 'likes'])
            ->where('status', 'published')
            ->when($request->filled('group_id'), function ($query) use ($request) {
                $query->where('community_group_id', $request->integer('group_id'));
            })
            ->latest()
            ->paginate(20);

        $posts->getCollection()->transform(function (CommunityPost $post) use ($userId) {
            return $this->decoratePostForUser($post, $userId);
        });

        return $this->successResponse($posts, 'تم جلب المنشورات بنجاح');
    }

    public function storePost(Request $request)
    {
        $validated = $request->validate([
            'group_id' => ['nullable', 'exists:community_groups,id'],
            'body' => ['required', 'string', 'max:5000'],
        ]);

        $post = CommunityPost::create([
            'community_group_id' => $validated['group_id'] ?? null,
            'user_id' => $request->user()->id,
            'content_ar' => $validated['body'],
            'status' => 'pending_review',
        ]);

        $post->load(['user.profile', 'group']);
        $post->loadCount(['comments', 'likes']);

        return $this->successResponse(
            $this->decoratePostForUser($post, $request->user()->id),
            'تم إرسال المنشور للمراجعة بنجاح',
            201
        );
    }

    public function storeComment(Request $request, CommunityPost $post)
    {
        if ($post->status !== 'published') {
            return $this->errorResponse('لا يمكن التعليق على هذا المنشور', null, 403);
        }

        $validated = $request->validate([
            'body' => ['nullable', 'string', 'max:2000'],
            'text' => ['nullable', 'string', 'max:2000'],
            'comment' => ['nullable', 'string', 'max:2000'],
            'content' => ['nullable', 'string', 'max:2000'],
        ]);

        $body = $validated['body']
            ?? $validated['text']
            ?? $validated['comment']
            ?? $validated['content']
            ?? null;

        if (trim((string) $body) === '') {
            return $this->errorResponse('نص التعليق مطلوب', null, 422);
        }

        $comment = null;

        DB::transaction(function () use ($request, $post, $body, &$comment) {
            $comment = $post->comments()->create([
                'user_id' => $request->user()->id,
                'content_ar' => $body,
            ]);

            $post->forceFill([
                'comments_count' => $post->comments()->count(),
            ])->save();
        });

        $comment->load('user.profile');

        return $this->successResponse(
            $this->formatComment($comment),
            'تم إضافة التعليق بنجاح',
            201
        );
    }

    public function toggleLike(Request $request, CommunityPost $post)
    {
        if ($post->status !== 'published') {
            return $this->errorResponse('لا يمكن التفاعل مع هذا المنشور', null, 403);
        }

        $liked = false;

        DB::transaction(function () use ($request, $post, &$liked) {
            $like = $post->likes()
                ->where('user_id', $request->user()->id)
                ->first();

            if ($like) {
                $like->delete();
                $liked = false;
            } else {
                $post->likes()->create([
                    'user_id' => $request->user()->id,
                ]);

                $liked = true;
            }

            $post->forceFill([
                'likes_count' => $post->likes()->count(),
            ])->save();
        });

        $freshPost = $post->fresh();

        return $this->successResponse([
            'liked' => $liked,
            'liked_by_me' => $liked,
            'likes_count' => $freshPost->likes_count,
            'post_id' => $freshPost->id,
        ], 'تم تحديث الإعجاب');
    }

    private function decorateGroupForUser(CommunityGroup $group, int $userId): CommunityGroup
    {
        $isMember = $group->members()
            ->where('user_id', $userId)
            ->exists();

        $group->setAttribute('title', $group->name_ar);
        $group->setAttribute('title_ar', $group->name_ar);
        $group->setAttribute('members_count', $group->members_count ?? $group->members()->count());
        $group->setAttribute('posts_count', $group->posts_count ?? $group->posts()->count());
        $group->setAttribute('is_member', $isMember);

        return $group;
    }

    private function decoratePostForUser(CommunityPost $post, int $userId): CommunityPost
    {
        $likedByMe = $post->likes()
            ->where('user_id', $userId)
            ->exists();

        $authorName = $post->user?->profile?->display_name
            ?? $post->user?->name;

        $authorAvatar = $post->user?->profile?->avatar;

        $comments = $post->relationLoaded('comments')
            ? $post->comments->map(function (CommunityComment $comment) {
                return $this->formatComment($comment);
            })->values()
            : collect();

        if ($post->relationLoaded('comments')) {
            $post->unsetRelation('comments');
        }

        $post->setAttribute('title', $post->title_ar);
        $post->setAttribute('body', $post->content_ar);
        $post->setAttribute('content', $post->content_ar);
        $post->setAttribute('author_name', $authorName);
        $post->setAttribute('author_avatar', $authorAvatar);
        $post->setAttribute('user_name', $authorName);
        $post->setAttribute('user_avatar', $authorAvatar);
        $post->setAttribute('group_name', $post->group?->name_ar);
        $post->setAttribute('group_title', $post->group?->name_ar);
        $post->setAttribute('likes_count', $post->likes_count ?? $post->likes()->count());
        $post->setAttribute('comments_count', $post->comments_count ?? $post->comments()->count());
        $post->setAttribute('comments', $comments);
        $post->setAttribute('liked_by_me', $likedByMe);
        $post->setAttribute('is_liked', $likedByMe);

        return $post;
    }

    private function formatComment(CommunityComment $comment): array
    {
        $authorName = $comment->user?->profile?->display_name
            ?? $comment->user?->name;

        return [
            'id' => $comment->id,
            'community_post_id' => $comment->community_post_id,
            'post_id' => $comment->community_post_id,
            'user_id' => $comment->user_id,
            'body' => $comment->content_ar,
            'content' => $comment->content_ar,
            'text' => $comment->content_ar,
            'content_ar' => $comment->content_ar,
            'author_name' => $authorName,
            'author_avatar' => $comment->user?->profile?->avatar,
            'user_name' => $authorName,
            'user_avatar' => $comment->user?->profile?->avatar,
            'created_at' => $comment->created_at?->toDateTimeString(),
            'updated_at' => $comment->updated_at?->toDateTimeString(),
        ];
    }
}