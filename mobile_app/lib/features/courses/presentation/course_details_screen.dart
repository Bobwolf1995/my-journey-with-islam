import 'package:flutter/material.dart';

import '../../../shared/theme/app_colors.dart';
import '../data/course_details.dart';
import '../data/courses_service.dart';
import 'lesson_details_page.dart';

class CourseDetailsScreen extends StatefulWidget {
  const CourseDetailsScreen({
    super.key,
    required this.courseId,
    required this.title,
    required this.subtitle,
    required this.progress,
    this.level = 'مبتدئ',
  });

  final int courseId;
  final String title;
  final String subtitle;
  final int progress;
  final String level;

  @override
  State<CourseDetailsScreen> createState() => _CourseDetailsScreenState();
}

class _CourseDetailsScreenState extends State<CourseDetailsScreen> {
  final CoursesService _coursesService = CoursesService();

  late Future<CourseDetails> _detailsFuture;

  bool _isEnrolling = false;

  @override
  void initState() {
    super.initState();
    _detailsFuture = _loadDetails();
  }

  Future<CourseDetails> _loadDetails() {
    return _coursesService.getCourseDetails(
      courseId: widget.courseId,
      fallbackTitle: widget.title,
      fallbackDescription: widget.subtitle,
      fallbackLevel: widget.level,
      fallbackProgress: widget.progress,
    );
  }

  Future<void> _refresh() async {
    setState(() {
      _detailsFuture = _loadDetails();
    });

    await _detailsFuture;
  }

  bool _hasLockedLessons(CourseDetails details) {
    for (final section in details.sections) {
      for (final lesson in section.lessons) {
        if (lesson.isEffectivelyLocked) {
          return true;
        }
      }
    }

    for (final lesson in details.standaloneLessons) {
      if (lesson.isEffectivelyLocked) {
        return true;
      }
    }

    return false;
  }

  Future<void> _enrollInCourse() async {
    if (_isEnrolling) {
      return;
    }

    setState(() {
      _isEnrolling = true;
    });

    final response = await _coursesService.enroll(courseId: widget.courseId);

    if (!mounted) {
      return;
    }

    final success = response['success'] == true;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'تم الاشتراك في الدورة بنجاح'
              : response['message']?.toString() ??
                  'تعذر الاشتراك في الدورة الآن',
          textAlign: TextAlign.right,
        ),
        backgroundColor: success ? AppColors.primary : AppColors.danger,
        behavior: SnackBarBehavior.floating,
      ),
    );

    if (success) {
      await _refresh();
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isEnrolling = false;
    });
  }

  Future<void> _openLesson(CourseLesson lesson) async {
    if (!lesson.isPublished) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'هذا الدرس غير متاح حاليًا',
            textAlign: TextAlign.right,
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (lesson.isEffectivelyLocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            lesson.lockReason.trim().isNotEmpty
                ? lesson.lockReason
                : 'يجب الاشتراك في الدورة لفتح هذا الدرس',
            textAlign: TextAlign.right,
          ),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LessonDetailsPage(
          lessonId: lesson.id,
        ),
      ),
    );

    if (!mounted) {
      return;
    }

    await _refresh();
  }

  CourseLesson? _firstPublishedLesson(CourseDetails details) {
    for (final section in details.sections) {
      for (final lesson in section.lessons) {
        if (lesson.isPublished && !lesson.isEffectivelyLocked) {
          return lesson;
        }
      }
    }

    for (final lesson in details.standaloneLessons) {
      if (lesson.isPublished && !lesson.isEffectivelyLocked) {
        return lesson;
      }
    }

    return null;
  }

  Future<void> _continueCourse(CourseDetails details) async {
    final lesson = _firstPublishedLesson(details);

    if (lesson == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'لا يوجد درس متاح حاليًا',
            textAlign: TextAlign.right,
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    await _openLesson(lesson);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: FutureBuilder<CourseDetails>(
          future: _detailsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return _LoadingView(title: widget.title);
            }

            final details = snapshot.data ??
                CourseDetails.fallback(
                  id: widget.courseId,
                  title: widget.title,
                  description: widget.subtitle,
                  level: widget.level,
                  progress: widget.progress,
                );

            final progress = details.progress.clamp(0, 100);
            final progressValue = progress / 100;
            final hasLockedLessons = _hasLockedLessons(details);

            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _refresh,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Header(title: details.title),
                    const SizedBox(height: 18),
                    _HeroCard(
                      title: details.title,
                      description: details.description,
                      level: details.level,
                      totalLessons: details.totalLessons,
                      progress: progress,
                      progressValue: progressValue,
                    ),
                    if (hasLockedLessons) ...[
                      const SizedBox(height: 14),
                      _CourseEnrollCard(
                        isLoading: _isEnrolling,
                        onPressed: _enrollInCourse,
                      ),
                    ],
                    const SizedBox(height: 20),
                    _LessonsSection(
                      details: details,
                      onLessonTap: _openLesson,
                    ),
                    const SizedBox(height: 18),
                    _ContinueCourseButton(
                      onPressed: () {
                        _continueCourse(details);
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView({
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(title: title),
          const Expanded(
            child: Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _CircleButton(
          icon: Icons.arrow_back_ios_new_rounded,
          onTap: () => Navigator.of(context).pop(),
        ),
        const Spacer(),
        Expanded(
          flex: 4,
          child: Text(
            title,
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 21,
              height: 1.25,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.title,
    required this.description,
    required this.level,
    required this.totalLessons,
    required this.progress,
    required this.progressValue,
  });

  final String title;
  final String description;
  final String level;
  final int totalLessons;
  final int progress;
  final double progressValue;

  @override
  Widget build(BuildContext context) {
    final safeProgress = progress.clamp(0, 100);

    return Container(
      padding: const EdgeInsets.all(20),
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
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.16),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 66,
            height: 66,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.18),
              ),
            ),
            child: const Icon(
              Icons.menu_book_rounded,
              color: Colors.white,
              size: 34,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              height: 1.3,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            description,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.84),
              fontSize: 14,
              height: 1.6,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _MetaPill(
                icon: Icons.signal_cellular_alt_rounded,
                label: level,
              ),
              const SizedBox(width: 8),
              _MetaPill(
                icon: Icons.play_lesson_rounded,
                label: '$totalLessons درس',
              ),
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progressValue,
              minHeight: 9,
              color: Colors.white,
              backgroundColor: Colors.white.withValues(alpha: 0.20),
            ),
          ),
          const SizedBox(height: 9),
          Text(
            '$safeProgress% مكتمل',
            textAlign: TextAlign.right,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.14),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 17),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  height: 1.2,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CourseEnrollCard extends StatelessWidget {
  const _CourseEnrollCard({
    required this.isLoading,
    required this.onPressed,
  });

  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.warning.withValues(alpha: 0.22),
        ),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            height: 46,
            child: ElevatedButton.icon(
              onPressed: isLoading ? null : onPressed,
              icon: isLoading
                  ? const SizedBox(
                      width: 17,
                      height: 17,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(
                      Icons.lock_open_rounded,
                      size: 19,
                    ),
              label: Text(
                isLoading ? 'جاري الاشتراك...' : 'افتح كل الدروس',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor:
                    AppColors.primary.withValues(alpha: 0.55),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.workspace_premium_rounded,
              color: AppColors.warning,
              size: 25,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'توجد دروس مقفلة',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 15,
                    height: 1.3,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'اشترك في الدورة للوصول إلى الدروس المقفلة.',
                  textAlign: TextAlign.right,
                  style: TextStyle(
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
    );
  }
}

class _LessonsSection extends StatelessWidget {
  const _LessonsSection({
    required this.details,
    required this.onLessonTap,
  });

  final CourseDetails details;
  final ValueChanged<CourseLesson> onLessonTap;

  @override
  Widget build(BuildContext context) {
    final hasSections = details.sections.isNotEmpty;
    final hasStandaloneLessons = details.standaloneLessons.isNotEmpty;

    if (!hasSections && !hasStandaloneLessons) {
      return const _EmptyLessons();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionTitle(title: 'دروس الدورة'),
        const SizedBox(height: 12),
        if (hasSections)
          for (final section in details.sections) ...[
            _SectionBlock(
              section: section,
              onLessonTap: onLessonTap,
            ),
            const SizedBox(height: 12),
          ],
        if (hasStandaloneLessons)
          _StandaloneLessonsBlock(
            lessons: details.standaloneLessons,
            onLessonTap: onLessonTap,
          ),
      ],
    );
  }
}

class _SectionBlock extends StatelessWidget {
  const _SectionBlock({
    required this.section,
    required this.onLessonTap,
  });

  final CourseSection section;
  final ValueChanged<CourseLesson> onLessonTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
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
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 15, 14, 11),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                section.title,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 16,
                  height: 1.3,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          for (var index = 0; index < section.lessons.length; index++)
            _LessonTile(
              lesson: section.lessons[index],
              isLast: index == section.lessons.length - 1,
              onTap: () => onLessonTap(section.lessons[index]),
            ),
        ],
      ),
    );
  }
}

class _StandaloneLessonsBlock extends StatelessWidget {
  const _StandaloneLessonsBlock({
    required this.lessons,
    required this.onLessonTap,
  });

  final List<CourseLesson> lessons;
  final ValueChanged<CourseLesson> onLessonTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
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
        children: [
          for (var index = 0; index < lessons.length; index++)
            _LessonTile(
              lesson: lessons[index],
              isLast: index == lessons.length - 1,
              onTap: () => onLessonTap(lessons[index]),
            ),
        ],
      ),
    );
  }
}

class _EmptyLessons extends StatelessWidget {
  const _EmptyLessons();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
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
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Icon(
              Icons.menu_book_outlined,
              color: AppColors.primary,
              size: 34,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'لم يتم إضافة دروس لهذه الدورة بعد.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 14,
              height: 1.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _LessonTile extends StatelessWidget {
  const _LessonTile({
    required this.lesson,
    required this.isLast,
    required this.onTap,
  });

  final CourseLesson lesson;
  final bool isLast;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isPublished = lesson.isPublished;
    final isLocked = lesson.isEffectivelyLocked;
    final isAvailable = isPublished && !isLocked;
    final badgeTitle = lesson.isFree ? 'مقفل' : 'مدفوع';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.vertical(
          bottom: isLast ? const Radius.circular(24) : Radius.zero,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
          decoration: BoxDecoration(
            color: isLocked
                ? AppColors.surfaceMuted.withValues(alpha: 0.34)
                : Colors.transparent,
            border: isLast
                ? null
                : const Border(
                    bottom: BorderSide(color: AppColors.borderSoft),
                  ),
          ),
          child: Row(
            children: [
              Icon(
                isAvailable
                    ? Icons.play_circle_outline
                    : Icons.lock_outline_rounded,
                color: isAvailable ? AppColors.primary : AppColors.textMuted,
                size: 26,
              ),
              const SizedBox(width: 12),
              Text(
                '${lesson.durationMinutes} دقيقة',
                style: TextStyle(
                  color: isLocked ? AppColors.textMuted : AppColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (isLocked) ...[
                const SizedBox(width: 8),
                _LessonLockBadge(title: badgeTitle),
              ],
              const Spacer(),
              Expanded(
                flex: 3,
                child: Text(
                  lesson.title,
                  textAlign: TextAlign.right,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isAvailable ? AppColors.text : AppColors.textMuted,
                    fontSize: 15,
                    height: 1.35,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: isAvailable
                      ? AppColors.primaryLight
                      : AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderSoft),
                ),
                child: Icon(
                  isAvailable
                      ? Icons.arrow_back_ios_new_rounded
                      : Icons.lock_rounded,
                  color: isAvailable ? AppColors.primary : AppColors.textMuted,
                  size: isAvailable ? 16 : 17,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LessonLockBadge extends StatelessWidget {
  const _LessonLockBadge({
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: AppColors.warning.withValues(alpha: 0.22),
        ),
      ),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.warning,
          fontSize: 10,
          height: 1.1,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _ContinueCourseButton extends StatelessWidget {
  const _ContinueCourseButton({
    required this.onPressed,
  });

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: const Icon(
          Icons.play_arrow_rounded,
          size: 24,
        ),
        label: const Text(
          'متابعة الدورة',
          style: TextStyle(
            fontSize: 16,
            height: 1.2,
            fontWeight: FontWeight.w900,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: AppColors.primary.withValues(alpha: 0.20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      textAlign: TextAlign.right,
      style: const TextStyle(
        color: AppColors.text,
        fontSize: 20,
        height: 1.25,
        fontWeight: FontWeight.w900,
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
          width: 44,
          height: 44,
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
          child: Icon(icon, color: AppColors.text, size: 20),
        ),
      ),
    );
  }
}
