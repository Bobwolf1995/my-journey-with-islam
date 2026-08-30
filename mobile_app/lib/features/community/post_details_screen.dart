import 'package:flutter/material.dart';

import '../../shared/theme/app_colors.dart';
import 'data/community_models.dart';
import 'data/community_service.dart';

class PostDetailsScreen extends StatefulWidget {
  const PostDetailsScreen({
    super.key,
    required this.post,
  });

  final CommunityPostSummary post;

  @override
  State<PostDetailsScreen> createState() => _PostDetailsScreenState();
}

class _PostDetailsScreenState extends State<PostDetailsScreen> {
  final CommunityService _communityService = CommunityService();
  final TextEditingController _commentController = TextEditingController();

  late CommunityPostSummary _post;
  late List<CommunityComment> _comments;
  late int _likesCount;
  late int _commentsCount;
  late bool _isLiked;

  bool _isLoadingLike = false;
  bool _isSaved = false;
  bool _isSendingComment = false;

  @override
  void initState() {
    super.initState();
    _post = widget.post;
    _comments = List<CommunityComment>.of(widget.post.comments);
    _likesCount = widget.post.likesCount;
    _commentsCount = _resolveCommentsCount(widget.post);
    _isLiked = false;
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  int _resolveCommentsCount(CommunityPostSummary post) {
    if (post.comments.length > post.commentsCount) {
      return post.comments.length;
    }

    return post.commentsCount;
  }

  Future<void> _refreshPost() async {
    final posts = await _communityService.getPosts();

    CommunityPostSummary? updatedPost;

    for (final post in posts) {
      if (post.id == _post.id) {
        updatedPost = post;
        break;
      }
    }

    if (!mounted || updatedPost == null) {
      return;
    }

    setState(() {
      _post = updatedPost!;
      _comments = List<CommunityComment>.of(updatedPost.comments);
      _likesCount = updatedPost.likesCount;
      _commentsCount = _resolveCommentsCount(updatedPost);
    });
  }

  Future<void> _toggleLike() async {
    if (_isLoadingLike) {
      return;
    }

    setState(() {
      _isLoadingLike = true;
    });

    final response = await _communityService.toggleLike(
      postId: _post.id,
    );

    if (!mounted) {
      return;
    }

    final isSuccess = response['success'] == true;
    final data = response['data'];

    if (isSuccess) {
      final liked = _boolFromData(
        data,
        keys: const ['liked', 'is_liked', 'isLiked'],
        fallback: !_isLiked,
      );

      final serverLikesCount = _intFromData(
        data,
        keys: const ['likes_count', 'likesCount', 'likes'],
      );

      setState(() {
        _isLiked = liked;
        _likesCount = serverLikesCount ?? (_likesCount + (liked ? 1 : -1));

        if (_likesCount < 0) {
          _likesCount = 0;
        }
      });
    }

    setState(() {
      _isLoadingLike = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isSuccess
              ? response['message']?.toString() ?? 'تم تحديث الإعجاب'
              : response['message']?.toString() ?? 'تعذر تنفيذ الإعجاب الآن',
          textAlign: TextAlign.right,
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isSuccess ? AppColors.primary : AppColors.danger,
      ),
    );
  }

  void _toggleSave() {
    setState(() {
      _isSaved = !_isSaved;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isSaved ? 'تم حفظ المنشور' : 'تم إلغاء حفظ المنشور',
          textAlign: TextAlign.right,
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primary,
      ),
    );
  }

  Future<void> _addComment() async {
    if (_isSendingComment) {
      return;
    }

    final body = _commentController.text.trim();

    if (body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'اكتب تعليقًا أولًا',
            textAlign: TextAlign.right,
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.danger,
        ),
      );

      return;
    }

    setState(() {
      _isSendingComment = true;
    });

    final response = await _communityService.addComment(
      postId: _post.id,
      body: body,
    );

    if (!mounted) {
      return;
    }

    final isSuccess = response['success'] == true;

    if (isSuccess) {
      _commentController.clear();
      FocusScope.of(context).unfocus();

      final commentData = _extractCommentData(response['data']);

      if (commentData != null) {
        setState(() {
          _comments.insert(0, CommunityComment.fromJson(commentData));
          _commentsCount = _comments.length;
        });
      }

      await _refreshPost();
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isSendingComment = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isSuccess
              ? response['message']?.toString() ?? 'تمت إضافة التعليق'
              : response['message']?.toString() ?? 'تعذر إضافة التعليق الآن',
          textAlign: TextAlign.right,
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isSuccess ? AppColors.primary : AppColors.danger,
      ),
    );
  }

  Map<String, dynamic>? _extractCommentData(dynamic data) {
    if (data is! Map<String, dynamic>) {
      return null;
    }

    if (_looksLikeComment(data)) {
      return data;
    }

    final comment = data['comment'];
    final item = data['item'];
    final nestedData = data['data'];

    if (comment is Map<String, dynamic>) {
      return comment;
    }

    if (item is Map<String, dynamic>) {
      return item;
    }

    if (nestedData is Map<String, dynamic>) {
      if (_looksLikeComment(nestedData)) {
        return nestedData;
      }

      final nestedComment = nestedData['comment'];

      if (nestedComment is Map<String, dynamic>) {
        return nestedComment;
      }
    }

    return null;
  }

  bool _looksLikeComment(Map<String, dynamic> data) {
    return data.containsKey('body') ||
        data.containsKey('content') ||
        data.containsKey('text') ||
        data.containsKey('content_ar');
  }

  bool _boolFromData(
    dynamic data, {
    required List<String> keys,
    required bool fallback,
  }) {
    if (data is Map<String, dynamic>) {
      for (final key in keys) {
        final value = data[key];

        if (value is bool) {
          return value;
        }

        if (value is num) {
          return value != 0;
        }

        if (value is String) {
          final normalized = value.trim().toLowerCase();

          if (normalized == 'true' || normalized == '1') {
            return true;
          }

          if (normalized == 'false' || normalized == '0') {
            return false;
          }
        }
      }
    }

    return fallback;
  }

  int? _intFromData(
    dynamic data, {
    required List<String> keys,
  }) {
    if (data is! Map<String, dynamic>) {
      return null;
    }

    for (final key in keys) {
      final value = data[key];

      if (value is int) {
        return value;
      }

      if (value is num) {
        return value.toInt();
      }

      if (value is String) {
        final parsed = int.tryParse(value);

        if (parsed != null) {
          return parsed;
        }
      }
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: AppColors.surface,
          onRefresh: _refreshPost,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _PostDetailsHeader(),
                const SizedBox(height: 18),
                _PostHeroCard(post: _post),
                const SizedBox(height: 14),
                _PostActionsCard(
                  likesCount: _likesCount,
                  commentsCount: _commentsCount,
                  isLiked: _isLiked,
                  isSaved: _isSaved,
                  isLoadingLike: _isLoadingLike,
                  onLikeTap: _toggleLike,
                  onSaveTap: _toggleSave,
                ),
                const SizedBox(height: 14),
                _CommentsCard(
                  comments: _comments,
                  controller: _commentController,
                  isSending: _isSendingComment,
                  onSend: _addComment,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PostDetailsHeader extends StatelessWidget {
  const _PostDetailsHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _CircleButton(
          icon: Icons.arrow_back_ios_new_rounded,
          onTap: () => Navigator.of(context).pop(true),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'تفاصيل المنشور',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 22,
                  height: 1.2,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'النقاش والتعليقات',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 56),
      ],
    );
  }
}

class _PostHeroCard extends StatelessWidget {
  const _PostHeroCard({
    required this.post,
  });

  final CommunityPostSummary post;

  @override
  Widget build(BuildContext context) {
    return _SoftCard(
      padding: const EdgeInsets.all(17),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                child: Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  alignment: WrapAlignment.start,
                  children: [
                    const _PostMetaChip(
                      icon: Icons.schedule_rounded,
                      label: 'الآن',
                      color: AppColors.textMuted,
                      backgroundColor: AppColors.surfaceSoft,
                    ),
                    _PostMetaChip(
                      icon: Icons.diversity_3_rounded,
                      label: post.groupName,
                      color: AppColors.primary,
                      backgroundColor: AppColors.primaryLight,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      post.authorName,
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 16,
                        height: 1.25,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      post.authorRole,
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                        height: 1.25,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 11),
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(17),
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: AppColors.primary,
                  size: 27,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          const Align(
            alignment: Alignment.centerRight,
            child: _PostTypeChip(),
          ),
          const SizedBox(height: 11),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 15,
              vertical: 14,
            ),
            decoration: BoxDecoration(
              color: AppColors.surfaceSoft,
              borderRadius: BorderRadius.circular(19),
              border: Border.all(color: AppColors.borderSoft),
            ),
            child: Text(
              post.body,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 16,
                height: 1.8,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PostTypeChip extends StatelessWidget {
  const _PostTypeChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'نقاش',
            style: TextStyle(
              color: AppColors.secondary,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(width: 5),
          Icon(
            Icons.forum_rounded,
            color: AppColors.secondary,
            size: 15,
          ),
        ],
      ),
    );
  }
}

class _PostMetaChip extends StatelessWidget {
  const _PostMetaChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.backgroundColor,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 135),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 5),
          Icon(icon, color: color, size: 15),
        ],
      ),
    );
  }
}

class _PostActionsCard extends StatelessWidget {
  const _PostActionsCard({
    required this.likesCount,
    required this.commentsCount,
    required this.isLiked,
    required this.isSaved,
    required this.isLoadingLike,
    required this.onLikeTap,
    required this.onSaveTap,
  });

  final int likesCount;
  final int commentsCount;
  final bool isLiked;
  final bool isSaved;
  final bool isLoadingLike;
  final VoidCallback onLikeTap;
  final VoidCallback onSaveTap;

  @override
  Widget build(BuildContext context) {
    return _SoftCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        children: [
          _ActionButton(
            icon: isSaved
                ? Icons.bookmark_rounded
                : Icons.bookmark_border_rounded,
            label: isSaved ? 'محفوظ' : 'حفظ',
            color: isSaved ? AppColors.primary : AppColors.textMuted,
            backgroundColor:
                isSaved ? AppColors.primaryLight : AppColors.surfaceSoft,
            onTap: onSaveTap,
          ),
          const SizedBox(width: 8),
          _ActionButton(
            icon: Icons.chat_bubble_outline_rounded,
            label: commentsCount.toString(),
            color: AppColors.textMuted,
            backgroundColor: AppColors.surfaceSoft,
            onTap: () {},
          ),
          const Spacer(),
          _ActionButton(
            icon: isLiked
                ? Icons.favorite_rounded
                : Icons.favorite_border_rounded,
            label: isLoadingLike ? '...' : likesCount.toString(),
            color: isLiked ? AppColors.danger : AppColors.primary,
            backgroundColor: isLiked
                ? AppColors.danger.withValues(alpha: 0.10)
                : AppColors.primaryLight,
            onTap: onLikeTap,
          ),
        ],
      ),
    );
  }
}

class _CommentsCard extends StatelessWidget {
  const _CommentsCard({
    required this.comments,
    required this.controller,
    required this.isSending,
    required this.onSend,
  });

  final List<CommunityComment> comments;
  final TextEditingController controller;
  final bool isSending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return _SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _SectionTitle(
            icon: Icons.chat_bubble_outline_rounded,
            title: 'التعليقات',
            subtitle: comments.isEmpty
                ? 'لا توجد تعليقات بعد'
                : '${comments.length} تعليق',
          ),
          const SizedBox(height: 14),
          _CommentInput(
            controller: controller,
            isSending: isSending,
            onSend: onSend,
          ),
          const SizedBox(height: 14),
          if (comments.isEmpty)
            const _EmptyComments()
          else
            for (var index = 0; index < comments.length; index++) ...[
              _CommentTile(comment: comments[index]),
              if (index != comments.length - 1) const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }
}

class _CommentInput extends StatelessWidget {
  const _CommentInput({
    required this.controller,
    required this.isSending,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool isSending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Material(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: isSending ? null : onSend,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.18),
                    blurRadius: 14,
                    offset: const Offset(0, 7),
                  ),
                ],
              ),
              child: isSending
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 21,
                    ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: controller,
            textAlign: TextAlign.right,
            minLines: 1,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'اكتب تعليقك هنا',
              hintStyle: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              filled: true,
              fillColor: AppColors.surfaceSoft,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.borderSoft),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.borderSoft),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({
    required this.comment,
  });

  final CommunityComment comment;

  String get _timeLabel {
    final createdAt = DateTime.tryParse(comment.createdAt);

    if (createdAt == null) {
      return 'الآن';
    }

    final difference = DateTime.now().difference(createdAt.toLocal());

    if (difference.inMinutes < 1) {
      return 'الآن';
    }

    if (difference.inHours < 1) {
      return 'منذ ${difference.inMinutes} د';
    }

    if (difference.inDays < 1) {
      return 'منذ ${difference.inHours} س';
    }

    return 'منذ ${difference.inDays} يوم';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            children: [
              _CommentTimeChip(label: _timeLabel),
              const Spacer(),
              Expanded(
                flex: 2,
                child: Text(
                  comment.authorName,
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: AppColors.primary,
                  size: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Text(
            comment.body,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 13,
              height: 1.6,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentTimeChip extends StatelessWidget {
  const _CommentTimeChip({
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _EmptyComments extends StatelessWidget {
  const _EmptyComments();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.chat_bubble_outline_rounded,
            color: AppColors.textMuted,
            size: 32,
          ),
          SizedBox(height: 8),
          Text(
            'لا توجد تعليقات بعد',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.text,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'كن أول من يشارك بتعليق في هذا النقاش.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              height: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = AppColors.primary,
    this.backgroundColor = AppColors.primaryLight,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          constraints: const BoxConstraints(minHeight: 36),
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.borderSoft),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 6),
              Icon(icon, color: color, size: 19),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: AppColors.primary, size: 21),
        ),
        const Spacer(),
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                title,
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 17,
                  height: 1.25,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                textAlign: TextAlign.right,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  height: 1.35,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SoftCard extends StatelessWidget {
  const _SoftCard({
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.borderSoft),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: AppColors.borderSoft),
            boxShadow: const [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 14,
                offset: Offset(0, 7),
              ),
            ],
          ),
          child: Icon(icon, color: AppColors.text, size: 20),
        ),
      ),
    );
  }
}
