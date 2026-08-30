import 'package:flutter/material.dart';

import '../../../shared/theme/app_colors.dart';
import '../../chat/presentation/chat_page.dart';
import '../data/community_models.dart';
import '../data/community_service.dart';
import '../group_details_screen.dart';
import '../post_details_screen.dart';

class CommunityPage extends StatefulWidget {
  const CommunityPage({
    super.key,
    this.onBackToHome,
  });

  final VoidCallback? onBackToHome;

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  final CommunityService _communityService = CommunityService();

  late Future<CommunityDashboard> _communityFuture;

  @override
  void initState() {
    super.initState();
    _communityFuture = _communityService.getDashboard();
  }

  Future<void> _refresh() async {
    setState(() {
      _communityFuture = _communityService.getDashboard();
    });

    await _communityFuture;
  }

  void _openSearch(CommunityDashboard dashboard) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return _CommunitySearchSheet(
          groups: dashboard.groups,
          posts: dashboard.posts,
          onPostChanged: _refresh,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: FutureBuilder<CommunityDashboard>(
        future: _communityFuture,
        builder: (context, snapshot) {
          final dashboard = snapshot.data ?? CommunityDashboard.fallback();

          return RefreshIndicator(
            color: AppColors.primary,
            backgroundColor: AppColors.surface,
            onRefresh: _refresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _CommunityHeader(
                    onSearch: () => _openSearch(dashboard),
                    onBackToHome: widget.onBackToHome,
                  ),
                  const SizedBox(height: 18),
                  const _MentorCard(),
                  const SizedBox(height: 22),
                  _SectionHeader(
                    title: 'مجموعات تناسب رحلتك',
                    subtitle: 'مساحات آمنة للأسئلة والمشاركة',
                    countLabel: '${dashboard.groups.length} مجموعة',
                  ),
                  const SizedBox(height: 12),
                  _GroupRow(groups: dashboard.groups),
                  const SizedBox(height: 24),
                  _SectionHeader(
                    title: 'نقاشات اليوم',
                    subtitle: 'أسئلة وتجارب من المجتمع',
                    countLabel: '${dashboard.posts.length} منشور',
                  ),
                  const SizedBox(height: 12),
                  _PostsList(
                    posts: dashboard.posts,
                    onPostChanged: _refresh,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CommunityHeader extends StatelessWidget {
  const _CommunityHeader({
    required this.onSearch,
    this.onBackToHome,
  });

  final VoidCallback onSearch;
  final VoidCallback? onBackToHome;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _CircleButton(
          icon: Icons.search_rounded,
          onTap: onSearch,
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'المجتمع',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 23,
                  height: 1.2,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'اسأل، شارك، وتعلّم مع الرفاق',
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _CircleButton(
          icon: Icons.arrow_back_ios_new_rounded,
          onTap: onBackToHome ?? () => Navigator.maybePop(context),
        ),
      ],
    );
  }
}

class _CommunitySearchSheet extends StatefulWidget {
  const _CommunitySearchSheet({
    required this.groups,
    required this.posts,
    this.onPostChanged,
  });

  final List<CommunityGroupSummary> groups;
  final List<CommunityPostSummary> posts;
  final Future<void> Function()? onPostChanged;

  @override
  State<_CommunitySearchSheet> createState() => _CommunitySearchSheetState();
}

class _CommunitySearchSheetState extends State<_CommunitySearchSheet> {
  final TextEditingController _searchController = TextEditingController();

  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<CommunityGroupSummary> get _filteredGroups {
    if (_query.isEmpty) {
      return widget.groups;
    }

    return widget.groups.where((group) {
      return _contains(group.title) || _contains(group.description);
    }).toList();
  }

  List<CommunityPostSummary> get _filteredPosts {
    if (_query.isEmpty) {
      return widget.posts;
    }

    return widget.posts.where((post) {
      return _contains(post.body) ||
          _contains(post.authorName) ||
          _contains(post.groupName);
    }).toList();
  }

  bool _contains(String value) {
    return value.toLowerCase().contains(_query.toLowerCase());
  }

  void _openGroup(CommunityGroupSummary group) {
    final navigator = Navigator.of(context);

    navigator.pop();
    navigator.push(
      MaterialPageRoute(
        builder: (_) => GroupDetailsScreen(group: group),
      ),
    );
  }

  Future<void> _openPost(CommunityPostSummary post) async {
    final navigator = Navigator.of(context);

    navigator.pop();

    final result = await navigator.push<bool>(
      MaterialPageRoute(
        builder: (_) => PostDetailsScreen(post: post),
      ),
    );

    if (result == true) {
      await widget.onPostChanged?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredGroups = _filteredGroups;
    final filteredPosts = _filteredPosts;
    final hasResults = filteredGroups.isNotEmpty || filteredPosts.isNotEmpty;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.82,
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'البحث في المجتمع',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: AppColors.text,
                fontSize: 21,
                height: 1.25,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'ابحث عن مجموعة أو منشور يناسب سؤالك.',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 13,
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _searchController,
              autofocus: true,
              textInputAction: TextInputAction.search,
              onChanged: (value) {
                setState(() {
                  _query = value.trim();
                });
              },
              decoration: InputDecoration(
                hintText: 'ابحث عن منشور أو مجموعة',
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppColors.primary,
                ),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _searchController.clear();

                          setState(() {
                            _query = '';
                          });
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(color: AppColors.borderSoft),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(color: AppColors.borderSoft),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: hasResults
                  ? ListView(
                      children: [
                        if (filteredGroups.isNotEmpty) ...[
                          _SearchSectionTitle(
                            title: 'المجموعات',
                            count: filteredGroups.length,
                          ),
                          const SizedBox(height: 8),
                          for (final group in filteredGroups) ...[
                            _SearchGroupTile(
                              group: group,
                              onTap: () => _openGroup(group),
                            ),
                            const SizedBox(height: 10),
                          ],
                        ],
                        if (filteredPosts.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          _SearchSectionTitle(
                            title: 'المنشورات',
                            count: filteredPosts.length,
                          ),
                          const SizedBox(height: 8),
                          for (final post in filteredPosts) ...[
                            _SearchPostTile(
                              post: post,
                              onTap: () {
                                _openPost(post);
                              },
                            ),
                            const SizedBox(height: 10),
                          ],
                        ],
                      ],
                    )
                  : const _SearchEmptyState(),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchSectionTitle extends StatelessWidget {
  const _SearchSectionTitle({
    required this.title,
    required this.count,
  });

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _SmallBadge(label: count.toString()),
        const Spacer(),
        Text(
          title,
          textAlign: TextAlign.right,
          style: const TextStyle(
            color: AppColors.text,
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _SearchGroupTile extends StatelessWidget {
  const _SearchGroupTile({
    required this.group,
    required this.onTap,
  });

  final CommunityGroupSummary group;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _SearchTile(
      icon: Icons.diversity_3_rounded,
      title: group.title,
      subtitle: '${group.membersCount} عضو - ${group.postsCount} منشور',
      onTap: onTap,
    );
  }
}

class _SearchPostTile extends StatelessWidget {
  const _SearchPostTile({
    required this.post,
    required this.onTap,
  });

  final CommunityPostSummary post;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _SearchTile(
      icon: Icons.forum_rounded,
      title: post.body,
      subtitle: '${post.authorName} - ${post.groupName}',
      onTap: onTap,
    );
  }
}

class _SearchTile extends StatelessWidget {
  const _SearchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.borderSoft),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      title,
                      textAlign: TextAlign.right,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 14,
                        height: 1.4,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchEmptyState extends StatelessWidget {
  const _SearchEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.borderSoft),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              color: AppColors.textMuted,
              size: 42,
            ),
            SizedBox(height: 10),
            Text(
              'لا توجد نتائج',
              style: TextStyle(
                color: AppColors.text,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'جرّب كلمة بحث مختلفة داخل المجموعات والمنشورات.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 13,
                height: 1.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MentorCard extends StatelessWidget {
  const _MentorCard();

  void _openChat(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const ChatPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: () => _openChat(context),
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                AppColors.primary,
                AppColors.primaryDark,
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.16),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
                child: const Icon(
                  Icons.support_agent_rounded,
                  color: Colors.white,
                  size: 31,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'تواصل مع مرشد',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        height: 1.25,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'اطرح سؤالك وتابع رحلتك مع مرشد موثوق.',
                      textAlign: TextAlign.right,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Color(0xFFE8F3EF),
                        fontSize: 12,
                        height: 1.45,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'ابدأ الآن',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GroupRow extends StatelessWidget {
  const _GroupRow({
    required this.groups,
  });

  final List<CommunityGroupSummary> groups;

  @override
  Widget build(BuildContext context) {
    final visibleGroups = groups.take(3).toList();

    if (visibleGroups.isEmpty) {
      return const _EmptyCommunityBlock(
        icon: Icons.diversity_3_outlined,
        title: 'لا توجد مجموعات الآن',
        message: 'اسحب للأسفل لتحديث المجموعات.',
      );
    }

    return Column(
      children: [
        for (var index = 0; index < visibleGroups.length; index++) ...[
          _GroupCard(
            group: visibleGroups[index],
            color: index.isEven ? AppColors.primary : AppColors.secondary,
            icon: index.isEven
                ? Icons.diversity_3_rounded
                : Icons.auto_stories_rounded,
          ),
          if (index != visibleGroups.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({
    required this.group,
    required this.color,
    required this.icon,
  });

  final CommunityGroupSummary group;
  final Color color;
  final IconData icon;

  void _openGroupDetails(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GroupDetailsScreen(group: group),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(21),
      child: InkWell(
        onTap: () => _openGroupDetails(context),
        borderRadius: BorderRadius.circular(21),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(21),
            border: Border.all(color: AppColors.borderSoft),
            boxShadow: const [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 14,
                offset: Offset(0, 7),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.11),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color, size: 27),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      group.title,
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 15,
                        height: 1.3,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      group.description,
                      textAlign: TextAlign.right,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                        height: 1.45,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 11),
                    Row(
                      children: [
                        _GroupMetaChip(
                          icon: Icons.forum_outlined,
                          label: '${group.postsCount} منشور',
                          color: AppColors.secondary,
                        ),
                        const SizedBox(width: 8),
                        _GroupMetaChip(
                          icon: Icons.people_outline_rounded,
                          label: '${group.membersCount} عضو',
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              const Icon(
                Icons.chevron_left_rounded,
                color: AppColors.textMuted,
                size: 26,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GroupMetaChip extends StatelessWidget {
  const _GroupMetaChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 5),
          Icon(icon, color: color, size: 15),
        ],
      ),
    );
  }
}

class _PostsList extends StatelessWidget {
  const _PostsList({
    required this.posts,
    required this.onPostChanged,
  });

  final List<CommunityPostSummary> posts;
  final Future<void> Function() onPostChanged;

  @override
  Widget build(BuildContext context) {
    if (posts.isEmpty) {
      return const _EmptyCommunityBlock(
        icon: Icons.forum_outlined,
        title: 'لا توجد نقاشات الآن',
        message: 'اسحب للأسفل لتحديث المنشورات.',
      );
    }

    return Column(
      children: [
        for (var index = 0; index < posts.length; index++) ...[
          _PostCard(
            post: posts[index],
            onPostChanged: onPostChanged,
          ),
          if (index != posts.length - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _PostCard extends StatefulWidget {
  const _PostCard({
    required this.post,
    required this.onPostChanged,
  });

  final CommunityPostSummary post;
  final Future<void> Function() onPostChanged;

  @override
  State<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<_PostCard> {
  final CommunityService _communityService = CommunityService();

  late int _likesCount;
  bool _isLiked = false;
  bool _isSaved = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _likesCount = widget.post.likesCount;
  }

  int get _commentsCount {
    if (widget.post.comments.length > widget.post.commentsCount) {
      return widget.post.comments.length;
    }

    return widget.post.commentsCount;
  }

  Future<void> _openPostDetails() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PostDetailsScreen(post: widget.post),
      ),
    );

    if (!mounted) {
      return;
    }

    if (result == true) {
      await widget.onPostChanged();
    }
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

  Future<void> _toggleLike() async {
    if (_isLoading) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final response = await _communityService.toggleLike(
      postId: widget.post.id,
    );

    if (!mounted) {
      return;
    }

    final isSuccess = response['success'] == true;
    final data = response['data'];

    final liked = _boolFromData(
      data,
      keys: const ['liked', 'is_liked', 'isLiked'],
      fallback: !_isLiked,
    );

    final serverLikesCount = _intFromData(
      data,
      keys: const ['likes_count', 'likesCount', 'likes'],
    );

    if (isSuccess) {
      setState(() {
        _isLiked = liked;
        _likesCount = serverLikesCount ?? (_likesCount + (liked ? 1 : -1));

        if (_likesCount < 0) {
          _likesCount = 0;
        }
      });
    }

    setState(() {
      _isLoading = false;
    });

    if (!isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            response['message']?.toString() ?? 'تعذر تنفيذ الإعجاب',
            textAlign: TextAlign.right,
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.danger,
        ),
      );
    }
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
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: () {
          _openPostDetails();
        },
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.borderSoft),
            boxShadow: const [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 16,
                offset: Offset(0, 8),
              ),
            ],
          ),
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
                          label: widget.post.groupName,
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
                          widget.post.authorName,
                          textAlign: TextAlign.right,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.text,
                            fontSize: 15,
                            height: 1.25,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.post.authorRole,
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
                    width: 48,
                    height: 48,
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
              const Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _PostTypeChip(),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 13,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSoft,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.borderSoft),
                ),
                child: Text(
                  widget.post.body,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 15,
                    height: 1.75,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  InkWell(
                    onTap: () {
                      _openPostDetails();
                    },
                    borderRadius: BorderRadius.circular(999),
                    child: const _PostAction(
                      icon: Icons.open_in_new_rounded,
                      label: 'التفاصيل',
                      color: AppColors.secondary,
                      backgroundColor: Color(0xFFFFF7E3),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: _toggleSave,
                    borderRadius: BorderRadius.circular(999),
                    child: _PostAction(
                      icon: _isSaved
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded,
                      label: _isSaved ? 'محفوظ' : 'حفظ',
                      color: _isSaved ? AppColors.primary : AppColors.textMuted,
                      backgroundColor: _isSaved
                          ? AppColors.primaryLight
                          : AppColors.surfaceSoft,
                    ),
                  ),
                  const Spacer(),
                  _PostAction(
                    icon: Icons.chat_bubble_outline_rounded,
                    label: _commentsCount.toString(),
                    backgroundColor: AppColors.surfaceSoft,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: _toggleLike,
                    borderRadius: BorderRadius.circular(999),
                    child: _PostAction(
                      icon: _isLiked
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      label: _isLoading ? '...' : _likesCount.toString(),
                      color: _isLiked ? AppColors.danger : AppColors.primary,
                      backgroundColor: _isLiked
                          ? AppColors.danger.withValues(alpha: 0.10)
                          : AppColors.primaryLight,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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

class _PostAction extends StatelessWidget {
  const _PostAction({
    required this.icon,
    required this.label,
    this.color = AppColors.primary,
    this.backgroundColor = AppColors.primaryLight,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 36),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
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
          const SizedBox(width: 5),
          Icon(icon, color: color, size: 18),
        ],
      ),
    );
  }
}

class _EmptyCommunityBlock extends StatelessWidget {
  const _EmptyCommunityBlock({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.borderSoft),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 14,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: AppColors.textMuted,
            size: 36,
          ),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.subtitle,
    required this.countLabel,
  });

  final String title;
  final String subtitle;
  final String countLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _SmallBadge(label: countLabel),
        const Spacer(),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              title,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 18,
                height: 1.25,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SmallBadge extends StatelessWidget {
  const _SmallBadge({
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
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
          ),
          child: Icon(icon, color: AppColors.text, size: 20),
        ),
      ),
    );
  }
}
