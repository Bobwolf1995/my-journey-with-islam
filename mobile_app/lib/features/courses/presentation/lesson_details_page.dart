import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/storage/token_storage.dart';
import '../../../shared/theme/app_colors.dart';
import '../data/lesson_service.dart';
import '../data/quiz_service.dart';

class LessonDetailsPage extends StatefulWidget {
  const LessonDetailsPage({
    super.key,
    this.lessonId = 1,
  });

  final int lessonId;

  @override
  State<LessonDetailsPage> createState() => _LessonDetailsPageState();
}

class _LessonDetailsPageState extends State<LessonDetailsPage> {
  final LessonService _lessonService = LessonService();
  final LessonFavoriteService _favoriteService = LessonFavoriteService();

  late Future<LessonDetails> _lessonFuture;

  LessonDetails? _lesson;
  bool _isCompleting = false;
  bool _isFavorite = false;
  bool _isFavoriteLoading = false;

  @override
  void initState() {
    super.initState();
    _lessonFuture = _loadLesson();
  }

  Future<LessonDetails> _loadLesson() async {
    final lesson = await _lessonService.getLesson(widget.lessonId);
    final isFavorite = await _favoriteService.isLessonFavorite(lesson.id);

    _lesson = lesson;
    _isFavorite = isFavorite;

    return lesson;
  }

  Future<void> _completeLesson() async {
    final currentLesson = _lesson;

    if (currentLesson == null || currentLesson.isCompleted || _isCompleting) {
      return;
    }

    setState(() {
      _isCompleting = true;
    });

    final response = await _lessonService.completeLesson(currentLesson.id);

    if (!mounted) {
      return;
    }

    final success = response['success'] == true;

    setState(() {
      _isCompleting = false;

      if (success) {
        _lesson = currentLesson.copyWith(isCompleted: true);
        _lessonFuture = Future.value(_lesson);
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'تم إكمال الدرس بنجاح'
              : response['message']?.toString() ?? 'تعذر إكمال الدرس الآن',
          textAlign: TextAlign.right,
        ),
        backgroundColor: success ? AppColors.primary : AppColors.danger,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _toggleFavorite() async {
    final currentLesson = _lesson;

    if (currentLesson == null || _isFavoriteLoading) {
      return;
    }

    setState(() {
      _isFavoriteLoading = true;
    });

    final response = await _favoriteService.toggleLesson(currentLesson.id);

    if (!mounted) {
      return;
    }

    final success = response['success'] == true;
    final isFavorite = _extractFavoriteState(
      response,
      fallback: !_isFavorite,
    );

    setState(() {
      _isFavoriteLoading = false;

      if (success) {
        _isFavorite = isFavorite;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? (_isFavorite
                  ? 'تمت إضافة الدرس إلى المفضلة'
                  : 'تم حذف الدرس من المفضلة')
              : response['message']?.toString() ?? 'تعذر تحديث المفضلة الآن',
          textAlign: TextAlign.right,
        ),
        backgroundColor: success ? AppColors.primary : AppColors.danger,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _openLessonResource(
    String url, {
    required String failureMessage,
  }) async {
    final text = url.trim();

    if (text.isEmpty) {
      return;
    }

    final uri = Uri.tryParse(text);

    if (uri == null) {
      _showLinkMessage(failureMessage);
      return;
    }

    final opened = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!opened && mounted) {
      _showLinkMessage(failureMessage);
    }
  }

  void _showLinkMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          textAlign: TextAlign.right,
        ),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  bool _extractFavoriteState(
    Map<String, dynamic> response, {
    required bool fallback,
  }) {
    final data = response['data'];

    if (data is Map<String, dynamic> && data['is_favorite'] is bool) {
      return data['is_favorite'] as bool;
    }

    if (response['is_favorite'] is bool) {
      return response['is_favorite'] as bool;
    }

    return fallback;
  }

  void _showQuiz() {
    final lesson = _lesson ?? LessonDetails.fallback();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return _LessonQuizSheet(lesson: lesson);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: FutureBuilder<LessonDetails>(
          future: _lessonFuture,
          builder: (context, snapshot) {
            final lesson = _lesson ?? snapshot.data ?? LessonDetails.fallback();

            if (snapshot.connectionState == ConnectionState.waiting &&
                _lesson == null) {
              return const _LoadingView();
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _LessonHeader(
                    isFavorite: _isFavorite,
                    isFavoriteLoading: _isFavoriteLoading,
                    onFavoriteTap: _toggleFavorite,
                  ),
                  const SizedBox(height: 18),
                  _LessonHero(lesson: lesson),
                  const SizedBox(height: 20),
                  const _SectionTitle(title: 'محتوى الدرس'),
                  const SizedBox(height: 10),
                  _LessonContentView(lesson: lesson),
                  if (lesson.hasResources) ...[
                    const SizedBox(height: 18),
                    _LessonResourcesCard(
                      fileUrl: lesson.fileUrl,
                      videoUrl: lesson.videoUrl,
                      audioUrl: lesson.audioUrl,
                      onOpenFile: () => _openLessonResource(
                        lesson.fileUrl,
                        failureMessage: 'تعذر فتح الملف الآن',
                      ),
                      onOpenVideo: () => _openLessonResource(
                        lesson.videoUrl,
                        failureMessage: 'تعذر فتح الفيديو الآن',
                      ),
                      onOpenAudio: () => _openLessonResource(
                        lesson.audioUrl,
                        failureMessage: 'تعذر فتح الصوت الآن',
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  _CompleteLessonCard(
                    isCompleted: lesson.isCompleted,
                    isCompleting: _isCompleting,
                    points: lesson.points,
                    onComplete: _completeLesson,
                  ),
                  const SizedBox(height: 18),
                  _QuizPromptCard(
                    lesson: lesson,
                    onTap: _showQuiz,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class LessonFavoriteService {
  LessonFavoriteService({
    ApiClient? apiClient,
    TokenStorage? tokenStorage,
  })  : _apiClient = apiClient ?? ApiClient(),
        _tokenStorage = tokenStorage ?? TokenStorage();

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  Future<bool> isLessonFavorite(int lessonId) async {
    try {
      final token = await _tokenStorage.getToken();

      final response = await _apiClient.get(
        '${ApiEndpoints.favorites}?type=lesson',
        token: token,
      );

      if (response['success'] != true) {
        return false;
      }

      final items = _extractItems(response);

      for (final item in items) {
        if (item is Map<String, dynamic>) {
          final type = item['type']?.toString();
          final favoriteId = _asInt(
            item['favoritable_id'] ?? item['favoriteable_id'] ?? item['id'],
            fallback: 0,
          );

          if (type == 'lesson' && favoriteId == lessonId) {
            return true;
          }
        }
      }

      return false;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>> toggleLesson(int lessonId) async {
    try {
      final token = await _tokenStorage.getToken();

      return _apiClient.post(
        ApiEndpoints.favoritesToggle,
        token: token,
        body: {
          'type': 'lesson',
          'id': lessonId,
          'favoritable_id': lessonId,
        },
      );
    } catch (_) {
      return {
        'success': false,
        'message': 'تعذر تحديث المفضلة الآن',
      };
    }
  }

  List<dynamic> _extractItems(Map<String, dynamic> response) {
    final data = response['data'];

    if (data is List) {
      return data;
    }

    if (data is Map<String, dynamic>) {
      final paginatedItems = data['data'];

      if (paginatedItems is List) {
        return paginatedItems;
      }

      final favorites = data['favorites'];

      if (favorites is List) {
        return favorites;
      }

      final items = data['items'];

      if (items is List) {
        return items;
      }
    }

    return const [];
  }

  int _asInt(dynamic value, {required int fallback}) {
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
}

class _LessonHeader extends StatelessWidget {
  const _LessonHeader({
    required this.isFavorite,
    required this.isFavoriteLoading,
    required this.onFavoriteTap,
  });

  final bool isFavorite;
  final bool isFavoriteLoading;
  final VoidCallback onFavoriteTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _CircleButton(
          icon: Icons.arrow_back_ios_new_rounded,
          onTap: () => Navigator.of(context).pop(),
        ),
        const Spacer(),
        const Text(
          'تفاصيل الدرس',
          style: TextStyle(
            color: AppColors.text,
            fontSize: 22,
            height: 1.25,
            fontWeight: FontWeight.w900,
          ),
        ),
        const Spacer(),
        _FavoriteButton(
          isFavorite: isFavorite,
          isLoading: isFavoriteLoading,
          onTap: onFavoriteTap,
        ),
      ],
    );
  }
}

class _FavoriteButton extends StatelessWidget {
  const _FavoriteButton({
    required this.isFavorite,
    required this.isLoading,
    required this.onTap,
  });

  final bool isFavorite;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isFavorite ? AppColors.danger : AppColors.text;

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: isFavorite
                ? AppColors.danger.withValues(alpha: 0.10)
                : AppColors.surfaceSoft,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isFavorite
                  ? AppColors.danger.withValues(alpha: 0.18)
                  : AppColors.borderSoft,
            ),
            boxShadow: const [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 16,
                offset: Offset(0, 7),
              ),
            ],
          ),
          child: isLoading
              ? const Padding(
                  padding: EdgeInsets.all(11),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                )
              : Icon(
                  isFavorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: color,
                  size: 20,
                ),
        ),
      ),
    );
  }
}

class _LessonHero extends StatelessWidget {
  const _LessonHero({
    required this.lesson,
  });

  final LessonDetails lesson;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 188),
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            AppColors.primaryDark,
            AppColors.primary,
            AppColors.accent,
          ],
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.16),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 82,
            height: 82,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.16),
              ),
            ),
            child: const Icon(
              Icons.menu_book_rounded,
              color: AppColors.secondary,
              size: 50,
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'الدرس ${lesson.id}',
                  style: const TextStyle(
                    color: Color(0xFFE8F3EF),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  lesson.title,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    height: 1.25,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  lesson.subtitle,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: Color(0xFFE8F3EF),
                    fontSize: 13,
                    height: 1.45,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                _LessonMetaRow(lesson: lesson),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LessonMetaRow extends StatelessWidget {
  const _LessonMetaRow({
    required this.lesson,
  });

  final LessonDetails lesson;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _MetaChip(icon: Icons.timer_outlined, title: lesson.duration),
        const SizedBox(width: 8),
        _MetaChip(
          icon: Icons.star_border_rounded,
          title: '${lesson.points} نقطة',
        ),
      ],
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.icon,
    required this.title,
  });

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.14),
        ),
      ),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 5),
          Icon(icon, color: Colors.white, size: 16),
        ],
      ),
    );
  }
}

class _LessonTextCard extends StatelessWidget {
  const _LessonTextCard({
    required this.content,
  });

  final String content;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.borderSoft),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 20,
            offset: Offset(0, 9),
          ),
        ],
      ),
      child: Text(
        content,
        textAlign: TextAlign.right,
        style: const TextStyle(
          color: AppColors.text,
          fontSize: 15,
          height: 1.78,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _LessonResourcesCard extends StatelessWidget {
  const _LessonResourcesCard({
    required this.fileUrl,
    required this.videoUrl,
    required this.audioUrl,
    required this.onOpenFile,
    required this.onOpenVideo,
    required this.onOpenAudio,
  });

  final String fileUrl;
  final String videoUrl;
  final String audioUrl;
  final VoidCallback onOpenFile;
  final VoidCallback onOpenVideo;
  final VoidCallback onOpenAudio;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.borderSoft),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 20,
            offset: Offset(0, 9),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const Text(
            'مرفقات الدرس',
            textAlign: TextAlign.right,
            style: TextStyle(
              color: AppColors.text,
              fontSize: 17,
              height: 1.3,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'يمكنك فتح المواد المرتبطة بهذا الدرس خارج التطبيق.',
            textAlign: TextAlign.right,
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              height: 1.45,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 8,
            runSpacing: 8,
            children: [
              if (fileUrl.isNotEmpty)
                _ResourceButton(
                  icon: Icons.description_rounded,
                  title: 'فتح الملف',
                  onTap: onOpenFile,
                ),
              if (videoUrl.isNotEmpty)
                _ResourceButton(
                  icon: Icons.play_circle_fill_rounded,
                  title: 'فتح الفيديو',
                  onTap: onOpenVideo,
                ),
              if (audioUrl.isNotEmpty)
                _ResourceButton(
                  icon: Icons.volume_up_rounded,
                  title: 'فتح الصوت',
                  onTap: onOpenAudio,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ResourceButton extends StatelessWidget {
  const _ResourceButton({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primaryLight,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 7),
              Icon(
                icon,
                color: AppColors.primary,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompleteLessonCard extends StatelessWidget {
  const _CompleteLessonCard({
    required this.isCompleted,
    required this.isCompleting,
    required this.points,
    required this.onComplete,
  });

  final bool isCompleted;
  final bool isCompleting;
  final int points;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    final title = isCompleted ? 'تم إكمال الدرس' : 'أنهيت قراءة الدرس؟';
    final subtitle = isCompleted
        ? 'تم تسجيل تقدمك وإضافة نقاط الدرس.'
        : 'اضغط على الزر بعد الانتهاء ليتم تحديث تقدمك.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: isCompleted ? AppColors.primaryLight : AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isCompleted ? AppColors.primaryLight : AppColors.borderSoft,
        ),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 20,
            offset: Offset(0, 9),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            children: [
              Icon(
                isCompleted
                    ? Icons.check_circle_rounded
                    : Icons.flag_circle_rounded,
                color: AppColors.primary,
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      title,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 17,
                        height: 1.3,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                        height: 1.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isCompleted ? AppColors.accent : AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor:
                    AppColors.primary.withValues(alpha: 0.45),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: isCompleted || isCompleting ? null : onComplete,
              icon: isCompleting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(
                      isCompleted
                          ? Icons.check_rounded
                          : Icons.done_all_rounded,
                      size: 20,
                    ),
              label: Text(
                isCompleted ? 'مكتمل' : 'أكملت الدرس +$points نقطة',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuizPromptCard extends StatelessWidget {
  const _QuizPromptCard({
    required this.lesson,
    required this.onTap,
  });

  final LessonDetails lesson;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final quiz = lesson.quiz;
    final hasRealQuiz = lesson.hasQuiz && quiz != null;
    final title =
        hasRealQuiz && quiz.titleAr.isNotEmpty ? quiz.titleAr : 'اختبر فهمك';
    final subtitle = hasRealQuiz
        ? '${quiz.questionsCount} سؤال • درجة النجاح ${quiz.passingScore}%'
        : 'أجب على اختبار قصير بعد قراءة الدرس.';

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          height: 116,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.borderSoft),
            boxShadow: const [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 20,
                offset: Offset(0, 9),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.surfaceSoft,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderSoft),
                ),
                child: const Icon(
                  Icons.chevron_left_rounded,
                  color: AppColors.textMuted,
                  size: 24,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.16),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.quiz_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 17,
                        height: 1.3,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
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

class _LessonQuizSheet extends StatefulWidget {
  const _LessonQuizSheet({
    required this.lesson,
  });

  final LessonDetails lesson;

  @override
  State<_LessonQuizSheet> createState() => _LessonQuizSheetState();
}

class _LessonQuizSheetState extends State<_LessonQuizSheet> {
  final QuizService _quizService = QuizService();

  int _currentQuestionIndex = 0;
  bool _isSubmitting = false;
  QuizSubmitResult? _submitResult;

  final Map<int, int> _selectedOptions = {};

  LessonQuiz? get _quiz => widget.lesson.quiz;

  List<LessonQuizQuestion> get _questions =>
      _quiz?.questions ?? const <LessonQuizQuestion>[];

  bool get _hasQuestions => _questions.isNotEmpty;

  LessonQuizQuestion? get _currentQuestion {
    if (!_hasQuestions) {
      return null;
    }

    return _questions[_currentQuestionIndex];
  }

  bool get _isLastQuestion {
    if (!_hasQuestions) {
      return true;
    }

    return _currentQuestionIndex == _questions.length - 1;
  }

  bool get _isSubmitted => _submitResult != null;

  void _selectOption(int optionIndex) {
    if (_isSubmitting || _isSubmitted) {
      return;
    }

    setState(() {
      _selectedOptions[_currentQuestionIndex] = optionIndex;
    });
  }

  void _goNext() {
    if (!_hasQuestions || _isSubmitting) {
      return;
    }

    if (_isSubmitted) {
      Navigator.pop(context);
      return;
    }

    if (!_isLastQuestion) {
      setState(() {
        _currentQuestionIndex++;
      });
      return;
    }

    _submitQuiz();
  }

  void _goPrevious() {
    if (_currentQuestionIndex == 0 || _isSubmitting || _isSubmitted) {
      return;
    }

    setState(() {
      _currentQuestionIndex--;
    });
  }

  Future<void> _submitQuiz() async {
    final quiz = _quiz;

    if (quiz == null || _questions.isEmpty || _isSubmitting) {
      return;
    }

    if (_selectedOptions.length < _questions.length) {
      _showQuizMessage('أجب على جميع الأسئلة قبل إرسال الاختبار');
      return;
    }

    final answers = <QuizAnswerPayload>[];

    for (var index = 0; index < _questions.length; index++) {
      final question = _questions[index];
      final selectedOptionIndex = _selectedOptions[index];

      if (selectedOptionIndex == null ||
          selectedOptionIndex < 0 ||
          selectedOptionIndex >= question.options.length) {
        _showQuizMessage('أجب على جميع الأسئلة قبل إرسال الاختبار');
        return;
      }

      answers.add(
        QuizAnswerPayload(
          questionId: question.id,
          optionId: question.options[selectedOptionIndex].id,
        ),
      );
    }

    setState(() {
      _isSubmitting = true;
    });

    final result = await _quizService.submitQuiz(
      quizId: quiz.id,
      answers: answers,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isSubmitting = false;
      _submitResult = result;
    });

    _showQuizMessage(result.message);
  }

  void _showQuizMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          textAlign: TextAlign.right,
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final quiz = _quiz;
    final title = quiz != null && quiz.titleAr.isNotEmpty
        ? quiz.titleAr
        : 'اختبار ${widget.lesson.title}';
    final description = quiz?.descriptionAr ?? '';
    final currentQuestion = _currentQuestion;
    final selectedOptionIndex = _selectedOptions[_currentQuestionIndex];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: SafeArea(
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.72,
          minChildSize: 0.42,
          maxChildSize: 0.92,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
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
                  Text(
                    title,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 20,
                      height: 1.3,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      description,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                        height: 1.55,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                  if (quiz != null) ...[
                    const SizedBox(height: 14),
                    Wrap(
                      alignment: WrapAlignment.end,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _QuizInfoChip(
                          icon: Icons.help_outline_rounded,
                          title: '${quiz.questionsCount} سؤال',
                        ),
                        _QuizInfoChip(
                          icon: Icons.verified_rounded,
                          title: 'النجاح ${quiz.passingScore}%',
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 18),
                  if (_submitResult != null) ...[
                    _QuizSubmitResultCard(result: _submitResult!),
                    const SizedBox(height: 16),
                  ],
                  if (!_hasQuestions)
                    const _QuizEmptyPreview()
                  else if (currentQuestion != null)
                    _InteractiveQuizQuestion(
                      questionNumber: _currentQuestionIndex + 1,
                      totalQuestions: _questions.length,
                      question: currentQuestion,
                      selectedOptionIndex: selectedOptionIndex,
                      onSelectOption: _selectOption,
                    ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: OutlinedButton(
                            onPressed: _currentQuestionIndex == 0 ||
                                    _isSubmitting ||
                                    _isSubmitted
                                ? null
                                : _goPrevious,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              disabledForegroundColor: AppColors.textMuted,
                              side: const BorderSide(
                                color: AppColors.borderSoft,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: const Text(
                              'السابق',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isSubmitting
                                ? null
                                : _hasQuestions
                                    ? _goNext
                                    : () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor:
                                  AppColors.primary.withValues(alpha: 0.45),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: _isSubmitting
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    _hasQuestions
                                        ? (_isSubmitted
                                            ? 'إغلاق'
                                            : _isLastQuestion
                                                ? 'إرسال'
                                                : 'التالي')
                                        : 'إغلاق',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_hasQuestions && !_isSubmitted) ...[
                    const SizedBox(height: 12),
                    const Text(
                      'سيتم إرسال إجاباتك عند الضغط على إرسال.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                        height: 1.4,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _QuizSubmitResultCard extends StatelessWidget {
  const _QuizSubmitResultCard({
    required this.result,
  });

  final QuizSubmitResult result;

  @override
  Widget build(BuildContext context) {
    final color = result.success && result.passed
        ? AppColors.primary
        : result.success
            ? AppColors.secondary
            : AppColors.danger;

    final icon = result.success && result.passed
        ? Icons.emoji_events_rounded
        : result.success
            ? Icons.info_rounded
            : Icons.error_outline_rounded;

    final title = result.success
        ? result.passed
            ? 'أحسنت، اجتزت الاختبار'
            : 'تم إرسال الاختبار'
        : 'تعذر إرسال الاختبار';

    final hasStats = result.totalQuestions > 0;
    final progress = (result.score.clamp(0, 100)) / 100;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: color.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      title,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: color,
                        fontSize: 17,
                        height: 1.3,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      result.message,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 12,
                        height: 1.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (hasStats) ...[
            const SizedBox(height: 15),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: Colors.white.withValues(alpha: 0.75),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _QuizResultMetric(
                    title: 'الإجابات الصحيحة',
                    value: '${result.correctAnswers}/${result.totalQuestions}',
                    color: color,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _QuizResultMetric(
                    title: 'النتيجة',
                    value: '${result.score}%',
                    color: color,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _QuizResultMetric extends StatelessWidget {
  const _QuizResultMetric({
    required this.title,
    required this.value,
    required this.color,
  });

  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: color,
              fontSize: 17,
              height: 1.2,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              height: 1.3,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuizInfoChip extends StatelessWidget {
  const _QuizInfoChip({
    required this.icon,
    required this.title,
  });

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 6),
          Icon(
            icon,
            color: AppColors.primary,
            size: 16,
          ),
        ],
      ),
    );
  }
}

class _InteractiveQuizQuestion extends StatelessWidget {
  const _InteractiveQuizQuestion({
    required this.questionNumber,
    required this.totalQuestions,
    required this.question,
    required this.selectedOptionIndex,
    required this.onSelectOption,
  });

  final int questionNumber;
  final int totalQuestions;
  final LessonQuizQuestion question;
  final int? selectedOptionIndex;
  final ValueChanged<int> onSelectOption;

  @override
  Widget build(BuildContext context) {
    final options = question.options;

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            children: [
              _QuizInfoChip(
                icon: Icons.stars_rounded,
                title: '${question.points} نقطة',
              ),
              const Spacer(),
              Text(
                'السؤال $questionNumber من $totalQuestions',
                textAlign: TextAlign.right,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            question.questionAr,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 16,
              height: 1.5,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (question.explanationAr.isNotEmpty) ...[
            const SizedBox(height: 7),
            Text(
              question.explanationAr,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                height: 1.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          if (options.isNotEmpty) ...[
            const SizedBox(height: 14),
            for (var index = 0; index < options.length; index++) ...[
              _QuizAnswerTile(
                title: options[index].optionAr,
                isSelected: selectedOptionIndex == index,
                isSubmitted: false,
                isCorrect: false,
                onTap: () => onSelectOption(index),
              ),
              if (index != options.length - 1) const SizedBox(height: 9),
            ],
          ] else ...[
            const SizedBox(height: 14),
            const Text(
              'لا توجد خيارات لهذا السؤال حاليًا.',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 13,
                height: 1.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _QuizEmptyPreview extends StatelessWidget {
  const _QuizEmptyPreview();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: const Text(
        'سيظهر محتوى الاختبار هنا عند توفر الأسئلة.',
        textAlign: TextAlign.right,
        style: TextStyle(
          color: AppColors.textMuted,
          fontSize: 13,
          height: 1.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _QuizAnswerTile extends StatelessWidget {
  const _QuizAnswerTile({
    required this.title,
    required this.isSelected,
    required this.isSubmitted,
    required this.isCorrect,
    required this.onTap,
  });

  final String title;
  final bool isSelected;
  final bool isSubmitted;
  final bool isCorrect;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final showCorrect = isSubmitted && isCorrect;
    final showWrong = isSubmitted && isSelected && !isCorrect;

    final color = showCorrect
        ? AppColors.primary
        : showWrong
            ? AppColors.danger
            : isSelected
                ? AppColors.primary
                : AppColors.border;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: color),
          ),
          child: Row(
            children: [
              Icon(
                showCorrect
                    ? Icons.check_circle_rounded
                    : showWrong
                        ? Icons.cancel_rounded
                        : isSelected
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_off_rounded,
                color: color,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: showWrong ? AppColors.danger : AppColors.text,
                    fontSize: 14,
                    height: 1.35,
                    fontWeight: FontWeight.w800,
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: AppColors.text,
        fontSize: 18,
        height: 1.3,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(
        color: AppColors.primary,
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
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.surfaceSoft,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderSoft),
            boxShadow: const [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 16,
                offset: Offset(0, 7),
              ),
            ],
          ),
          child: Icon(icon, color: AppColors.text, size: 18),
        ),
      ),
    );
  }
}

class _LessonContentView extends StatelessWidget {
  const _LessonContentView({
    required this.lesson,
  });

  final LessonDetails lesson;

  @override
  Widget build(BuildContext context) {
    if (lesson.contents.isEmpty) {
      return _LessonTextCard(content: lesson.content);
    }

    final blocks = [...lesson.contents]
      ..sort((first, second) => first.order.compareTo(second.order));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var index = 0; index < blocks.length; index++) ...[
          _LessonContentBlockView(block: blocks[index]),
          if (index != blocks.length - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _LessonContentBlockView extends StatelessWidget {
  const _LessonContentBlockView({
    required this.block,
  });

  final LessonContentBlock block;

  @override
  Widget build(BuildContext context) {
    final type = block.type.trim().toLowerCase();

    switch (type) {
      case 'subtitle':
        return _LessonSubtitleBlock(
          title: _blockTitleOrContent(block),
        );
      case 'paragraph':
        return _LessonParagraphBlock(
          content: _blockContentOrTitle(block),
        );
      case 'bullet_list':
        final items = _extractBulletItems(block.meta);

        if (items.isEmpty) {
          return _LessonParagraphBlock(
            content: _blockContentOrTitle(block),
          );
        }

        return _LessonBulletListBlock(
          title: block.titleAr,
          items: items,
        );
      case 'important_note':
        return _LessonNoteBlock(
          icon: Icons.lightbulb_rounded,
          title: block.titleAr.isEmpty ? 'تنبيه مهم' : block.titleAr,
          content: block.contentAr,
          backgroundColor: AppColors.primaryLight,
          iconColor: AppColors.primary,
        );
      case 'common_mistake':
        return _LessonNoteBlock(
          icon: Icons.warning_amber_rounded,
          title: block.titleAr.isEmpty ? 'خطأ شائع' : block.titleAr,
          content: block.contentAr,
          backgroundColor: AppColors.secondary.withValues(alpha: 0.14),
          iconColor: AppColors.secondary,
        );
      case 'summary':
        return _LessonNoteBlock(
          icon: Icons.check_circle_rounded,
          title: block.titleAr.isEmpty ? 'ملخص الدرس' : block.titleAr,
          content: block.contentAr,
          backgroundColor: AppColors.surfaceSoft,
          iconColor: AppColors.primary,
        );
      case 'image':
      case 'video':
      case 'audio':
      case 'file':
        return _LessonAttachmentBlock(
          title: block.titleAr,
          type: type,
        );
      default:
        return _LessonParagraphBlock(
          content: _blockContentOrTitle(block),
        );
    }
  }

  static String _blockTitleOrContent(LessonContentBlock block) {
    if (block.titleAr.trim().isNotEmpty) {
      return block.titleAr.trim();
    }

    return block.contentAr.trim();
  }

  static String _blockContentOrTitle(LessonContentBlock block) {
    if (block.contentAr.trim().isNotEmpty) {
      return block.contentAr.trim();
    }

    return block.titleAr.trim();
  }

  static List<String> _extractBulletItems(Map<String, dynamic> meta) {
    final value = meta['items'] ?? meta['list'] ?? meta['points'];

    if (value is List) {
      return value
          .map((item) => item?.toString().trim() ?? '')
          .where((item) => item.isNotEmpty)
          .toList();
    }

    if (value is String && value.trim().isNotEmpty) {
      return value
          .split('\n')
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }

    return const [];
  }
}

class _LessonSubtitleBlock extends StatelessWidget {
  const _LessonSubtitleBlock({
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      textAlign: TextAlign.right,
      style: const TextStyle(
        color: AppColors.primary,
        fontSize: 17,
        height: 1.35,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _LessonParagraphBlock extends StatelessWidget {
  const _LessonParagraphBlock({
    required this.content,
  });

  final String content;

  @override
  Widget build(BuildContext context) {
    return _LessonTextCard(content: content);
  }
}

class _LessonBulletListBlock extends StatelessWidget {
  const _LessonBulletListBlock({
    required this.title,
    required this.items,
  });

  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.borderSoft),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 20,
            offset: Offset(0, 9),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (title.trim().isNotEmpty) ...[
            Text(
              title.trim(),
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 16,
                height: 1.35,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
          ],
          for (final item in items) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    item,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 14,
                      height: 1.7,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 9),
                Container(
                  width: 7,
                  height: 7,
                  margin: const EdgeInsets.only(top: 9),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            if (item != items.last) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _LessonNoteBlock extends StatelessWidget {
  const _LessonNoteBlock({
    required this.icon,
    required this.title,
    required this.content,
    required this.backgroundColor,
    required this.iconColor,
  });

  final IconData icon;
  final String title;
  final String content;
  final Color backgroundColor;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.70),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 23,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 16,
                    height: 1.35,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (content.trim().isNotEmpty) ...[
                  const SizedBox(height: 7),
                  Text(
                    content.trim(),
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 14,
                      height: 1.65,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LessonAttachmentBlock extends StatelessWidget {
  const _LessonAttachmentBlock({
    required this.title,
    required this.type,
  });

  final String title;
  final String type;

  @override
  Widget build(BuildContext context) {
    final label = switch (type) {
      'image' => 'صورة تعليمية متوفرة',
      'video' => 'فيديو تعليمي متوفر',
      'audio' => 'ملف صوتي تعليمي متوفر',
      'file' => 'ملف تعليمي متوفر',
      _ => 'مرفق تعليمي متوفر',
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.attach_file_rounded,
            color: AppColors.primary,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title.trim().isEmpty ? label : title.trim(),
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 14,
                height: 1.45,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
