class CommunityDashboard {
  const CommunityDashboard({
    required this.groups,
    required this.posts,
  });

  final List<CommunityGroupSummary> groups;
  final List<CommunityPostSummary> posts;

  factory CommunityDashboard.fallback() {
    return CommunityDashboard(
      groups: [
        CommunityGroupSummary.fallback(
          id: 0,
          title: 'المسلمون الجدد',
          description: 'مساحة آمنة للأسئلة والدعم اليومي.',
          membersCount: 128,
          postsCount: 42,
        ),
        CommunityGroupSummary.fallback(
          id: 0,
          title: 'حفظ القرآن',
          description: 'تشجيع ومتابعة ورد الحفظ والمراجعة.',
          membersCount: 84,
          postsCount: 21,
        ),
      ],
      posts: [
        CommunityPostSummary.fallback(
          id: 0,
          authorName: 'محمد السعيد',
          authorRole: 'طالب علم',
          body: 'ما أفضل طريقة للمحافظة على ورد يومي ثابت مع الدروس؟',
          groupName: 'المسلمون الجدد',
          likesCount: 18,
          commentsCount: 7,
        ),
      ],
    );
  }
}

class CommunityGroupSummary {
  const CommunityGroupSummary({
    required this.id,
    required this.title,
    required this.description,
    required this.membersCount,
    required this.postsCount,
  });

  final int id;
  final String title;
  final String description;
  final int membersCount;
  final int postsCount;

  factory CommunityGroupSummary.fallback({
    required int id,
    required String title,
    required String description,
    required int membersCount,
    required int postsCount,
  }) {
    return CommunityGroupSummary(
      id: id,
      title: title,
      description: description,
      membersCount: membersCount,
      postsCount: postsCount,
    );
  }

  factory CommunityGroupSummary.fromJson(Map<String, dynamic> json) {
    return CommunityGroupSummary(
      id: _int(json['id'], fallback: 0),
      title: _string(
        json['name_ar'] ?? json['title_ar'] ?? json['name'] ?? json['title'],
        fallback: 'مجموعة',
      ),
      description: _string(
        json['description_ar'] ??
            json['short_description_ar'] ??
            json['description'] ??
            json['summary'],
        fallback: 'مجموعة للتواصل والتعلم.',
      ),
      membersCount: _int(
        json['members_count'] ??
            json['total_members'] ??
            json['users_count'] ??
            json['membersCount'],
        fallback: 0,
      ),
      postsCount: _int(
        json['posts_count'] ??
            json['total_posts'] ??
            json['discussions_count'] ??
            json['postsCount'],
        fallback: 0,
      ),
    );
  }
}

class CommunityPostSummary {
  const CommunityPostSummary({
    required this.id,
    required this.authorName,
    required this.authorRole,
    required this.body,
    required this.groupName,
    required this.likesCount,
    required this.commentsCount,
    this.comments = const [],
  });

  final int id;
  final String authorName;
  final String authorRole;
  final String body;
  final String groupName;
  final int likesCount;
  final int commentsCount;
  final List<CommunityComment> comments;

  factory CommunityPostSummary.fallback({
    required int id,
    required String authorName,
    required String authorRole,
    required String body,
    required String groupName,
    required int likesCount,
    required int commentsCount,
  }) {
    return CommunityPostSummary(
      id: id,
      authorName: authorName,
      authorRole: authorRole,
      body: body,
      groupName: groupName,
      likesCount: likesCount,
      commentsCount: commentsCount,
    );
  }

  factory CommunityPostSummary.fromJson(Map<String, dynamic> json) {
    final user = _map(json['user'] ?? json['author'] ?? json['member']);
    final profile = _map(user['profile']);

    final group = _map(
      json['group'] ??
          json['community_group'] ??
          json['communityGroup'] ??
          json['category'],
    );

    final comments = _comments(
      json['comments'] ??
          json['post_comments'] ??
          json['community_comments'] ??
          json['replies'],
    );

    return CommunityPostSummary(
      id: _int(json['id'], fallback: 0),
      authorName: _string(
        profile['display_name'] ??
            user['display_name'] ??
            user['name'] ??
            json['author_name'] ??
            json['user_name'],
        fallback: 'عضو في المجتمع',
      ),
      authorRole: _string(
        profile['role'] ?? user['role'] ?? json['author_role'],
        fallback: 'طالب علم',
      ),
      body: _string(
        json['body'] ??
            json['content'] ??
            json['message'] ??
            json['text'] ??
            json['description'],
        fallback: 'منشور من المجتمع',
      ),
      groupName: _string(
        group['name_ar'] ??
            group['title_ar'] ??
            group['name'] ??
            group['title'] ??
            json['group_name'],
        fallback: 'المجتمع',
      ),
      likesCount: _int(
        json['likes_count'] ??
            json['likes'] ??
            json['reactions_count'] ??
            json['favorites_count'],
        fallback: 0,
      ),
      commentsCount: _int(
        json['comments_count'] ??
            json['replies_count'] ??
            json['answers_count'],
        fallback: comments.length,
      ),
      comments: comments,
    );
  }
}

class CommunityComment {
  const CommunityComment({
    required this.id,
    required this.postId,
    required this.authorName,
    required this.authorAvatar,
    required this.body,
    required this.createdAt,
  });

  final int id;
  final int postId;
  final String authorName;
  final String authorAvatar;
  final String body;
  final String createdAt;

  factory CommunityComment.fromJson(Map<String, dynamic> json) {
    final user = _map(json['user'] ?? json['author']);
    final profile = _map(user['profile']);

    return CommunityComment(
      id: _int(json['id'], fallback: 0),
      postId: _int(
        json['community_post_id'] ?? json['post_id'],
        fallback: 0,
      ),
      authorName: _string(
        json['author_name'] ??
            json['user_name'] ??
            profile['display_name'] ??
            user['display_name'] ??
            user['name'],
        fallback: 'عضو في المجتمع',
      ),
      authorAvatar: _string(
        json['author_avatar'] ??
            json['user_avatar'] ??
            profile['avatar'] ??
            user['avatar'],
        fallback: '',
      ),
      body: _string(
        json['body'] ??
            json['content'] ??
            json['text'] ??
            json['content_ar'] ??
            json['message'],
        fallback: 'تعليق من المجتمع',
      ),
      createdAt: _string(
        json['created_at'],
        fallback: '',
      ),
    );
  }
}

class CommunityListResult<T> {
  const CommunityListResult({
    required this.items,
  });

  final List<T> items;
}

List<CommunityComment> _comments(dynamic value) {
  if (value is! List) {
    return const [];
  }

  return value
      .whereType<Map<String, dynamic>>()
      .map(CommunityComment.fromJson)
      .toList();
}

Map<String, dynamic> _map(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }

  return <String, dynamic>{};
}

String _string(dynamic value, {required String fallback}) {
  if (value is String && value.trim().isNotEmpty) {
    return value.trim();
  }

  return fallback;
}

int _int(dynamic value, {required int fallback}) {
  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  if (value is String) {
    return int.tryParse(value) ?? fallback;
  }

  return fallback;
}
