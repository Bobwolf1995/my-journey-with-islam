import 'package:flutter/material.dart';

import '../../../shared/theme/app_colors.dart';
import '../data/course_summary.dart';
import '../data/courses_service.dart';
import 'course_details_screen.dart';

class CoursesPage extends StatefulWidget {
  const CoursesPage({
    super.key,
    this.initialPathTitle,
    this.onBackToHome,
  });

  final String? initialPathTitle;
  final VoidCallback? onBackToHome;

  @override
  State<CoursesPage> createState() => _CoursesPageState();
}

class _CoursesPageState extends State<CoursesPage> {
  final CoursesService _coursesService = CoursesService();

  late Future<CoursesResult> _coursesFuture;

  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _coursesFuture = _coursesService.getCourses();
  }

  Future<void> _refresh() async {
    setState(() {
      _coursesFuture = _coursesService.getCourses();
    });

    await _coursesFuture;
  }

  void _changeTab(int index) {
    setState(() {
      _selectedTabIndex = index;
    });
  }

  List<CourseSummary> _visibleCourses(List<CourseSummary> courses) {
    if (_selectedTabIndex == 1) {
      return courses;
    }

    final selectedPathTitle = widget.initialPathTitle;

    if (selectedPathTitle == null || selectedPathTitle.trim().isEmpty) {
      return courses.where((course) => course.progress > 0).toList();
    }

    return courses
        .where((course) => _courseMatchesPath(course, selectedPathTitle))
        .toList();
  }

  bool _courseMatchesPath(CourseSummary course, String pathTitle) {
    final normalizedPathTitle = _normalize(pathTitle);
    final normalizedTitle = _normalize(course.title);
    final normalizedSubtitle = _normalize(course.subtitle);
    final normalizedIconName = _normalize(course.iconName);

    if (normalizedPathTitle.contains('العبادات')) {
      return _containsAny(normalizedTitle, ['العبادات', 'الصلاه', 'الطهاره']) ||
          _containsAny(normalizedSubtitle, [
            'العبادات',
            'الصلاه',
            'الطهاره',
          ]) ||
          normalizedIconName.contains('prayer');
    }

    if (normalizedPathTitle.contains('العقيده')) {
      return _containsAny(normalizedTitle, ['العقيده', 'الايمان']) ||
          _containsAny(normalizedSubtitle, ['العقيده', 'الايمان']) ||
          normalizedIconName.contains('star') ||
          normalizedIconName.contains('aqeeda');
    }

    if (normalizedPathTitle.contains('السيره')) {
      return _containsAny(normalizedTitle, ['السيره']) ||
          _containsAny(normalizedSubtitle, ['السيره', 'النبي']) ||
          normalizedIconName.contains('history') ||
          normalizedIconName.contains('sira');
    }

    if (normalizedPathTitle.contains('الاساسي')) {
      return _containsAny(normalizedTitle, ['الاساسي', 'الاساسيات']) ||
          _containsAny(normalizedSubtitle, ['الاساسي', 'الاساسيات']) ||
          normalizedIconName.contains('book') ||
          normalizedIconName.contains('mosque');
    }

    return normalizedTitle.contains(normalizedPathTitle) ||
        normalizedPathTitle.contains(normalizedTitle) ||
        normalizedSubtitle.contains(normalizedPathTitle);
  }

  bool _containsAny(String value, List<String> keywords) {
    return keywords.any(value.contains);
  }

  String _normalize(String value) {
    return value
        .trim()
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('ة', 'ه')
        .toLowerCase();
  }

  String get _currentTabTitle {
    final selectedPathTitle = widget.initialPathTitle;

    if (selectedPathTitle == null || selectedPathTitle.trim().isEmpty) {
      return 'المسار الحالي';
    }

    return selectedPathTitle;
  }

  String get _emptyMessage {
    final selectedPathTitle = widget.initialPathTitle;

    if (selectedPathTitle == null || selectedPathTitle.trim().isEmpty) {
      return 'لا توجد دورات قيد التقدم حاليًا.';
    }

    return 'لا توجد دورات ضمن $selectedPathTitle حاليًا.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: FutureBuilder<CoursesResult>(
          future: _coursesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return _CoursesLoadingView(
                onBackToHome: widget.onBackToHome,
              );
            }

            final result = snapshot.data ??
                CoursesResult.failure(
                  message: 'تعذر تحميل الدورات الآن',
                );

            if (!result.isSuccess) {
              return RefreshIndicator(
                color: AppColors.primary,
                onRefresh: _refresh,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _CoursesHeader(
                        onBackToHome: widget.onBackToHome,
                      ),
                      const SizedBox(height: 20),
                      _CoursesStatusMessage(
                        icon: Icons.cloud_off_rounded,
                        title: 'تعذر تحميل الدورات',
                        message: result.message,
                        onRetry: () {
                          _refresh();
                        },
                      ),
                    ],
                  ),
                ),
              );
            }

            final visibleCourses = _visibleCourses(result.courses);

            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _refresh,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _CoursesHeader(
                      onBackToHome: widget.onBackToHome,
                    ),
                    const SizedBox(height: 20),
                    _SegmentedTabs(
                      currentTitle: _currentTabTitle,
                      selectedIndex: _selectedTabIndex,
                      onChanged: _changeTab,
                    ),
                    const SizedBox(height: 18),
                    if (visibleCourses.isEmpty)
                      _EmptyCoursesMessage(message: _emptyMessage)
                    else
                      for (final course in visibleCourses) ...[
                        _PathCard(course: course),
                        const SizedBox(height: 12),
                      ],
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

class _CoursesLoadingView extends StatelessWidget {
  const _CoursesLoadingView({
    this.onBackToHome,
  });

  final VoidCallback? onBackToHome;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CoursesHeader(
            onBackToHome: onBackToHome,
          ),
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

class _CoursesHeader extends StatelessWidget {
  const _CoursesHeader({
    this.onBackToHome,
  });

  final VoidCallback? onBackToHome;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _CircleButton(
          icon: Icons.arrow_back_ios_new_rounded,
          onTap: onBackToHome ?? () => Navigator.maybePop(context),
        ),
        const Spacer(),
        const Text(
          'دوراتي',
          textAlign: TextAlign.right,
          style: TextStyle(
            color: AppColors.text,
            fontSize: 23,
            height: 1.2,
            fontWeight: FontWeight.w900,
          ),
        ),
        const Spacer(),
        const SizedBox(width: 44),
      ],
    );
  }
}

class _SegmentedTabs extends StatelessWidget {
  const _SegmentedTabs({
    required this.currentTitle,
    required this.selectedIndex,
    required this.onChanged,
  });

  final String currentTitle;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Row(
        children: [
          Expanded(
            child: _TabItem(
              title: currentTitle,
              selected: selectedIndex == 0,
              onTap: () => onChanged(0),
            ),
          ),
          Expanded(
            child: _TabItem(
              title: 'جميع المسارات',
              selected: selectedIndex == 1,
              onTap: () => onChanged(1),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.title,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            boxShadow: selected
                ? const [
                    BoxShadow(
                      color: AppColors.shadow,
                      blurRadius: 14,
                      offset: Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: selected ? AppColors.primary : AppColors.textMuted,
              fontSize: 13,
              height: 1.2,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _CoursesStatusMessage extends StatelessWidget {
  const _CoursesStatusMessage({
    required this.icon,
    required this.title,
    required this.message,
    required this.onRetry,
  });

  final IconData icon;
  final String title;
  final String message;
  final VoidCallback onRetry;

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
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 66,
            height: 66,
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Icon(
              icon,
              color: AppColors.textMuted,
              size: 34,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 17,
              height: 1.3,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 13,
              height: 1.55,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 44,
            child: ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text(
                'إعادة المحاولة',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyCoursesMessage extends StatelessWidget {
  const _EmptyCoursesMessage({
    required this.message,
  });

  final String message;

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
            blurRadius: 22,
            offset: Offset(0, 10),
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
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 13,
              height: 1.55,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _PathCard extends StatelessWidget {
  const _PathCard({
    required this.course,
  });

  final CourseSummary course;

  Future<void> _openDetails(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CourseDetailsScreen(
          courseId: course.id,
          title: course.title,
          subtitle: course.subtitle,
          progress: course.progress,
        ),
      ),
    );
  }

  IconData get _icon {
    final icon = course.iconName.toLowerCase();

    if (icon.contains('star') || icon.contains('aqeeda')) {
      return Icons.auto_awesome_rounded;
    }

    if (icon.contains('prayer') || icon.contains('mosque')) {
      return Icons.mosque_rounded;
    }

    if (icon.contains('history') || icon.contains('sira')) {
      return Icons.history_edu_rounded;
    }

    return Icons.menu_book_rounded;
  }

  Color get _iconColor {
    final icon = course.iconName.toLowerCase();

    if (icon.contains('star') || icon.contains('aqeeda')) {
      return const Color(0xFF6D5EA8);
    }

    if (icon.contains('prayer') || icon.contains('mosque')) {
      return const Color(0xFF2C7DA0);
    }

    if (icon.contains('history') || icon.contains('sira')) {
      return AppColors.secondary;
    }

    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    final progress = course.progress.clamp(0, 100);
    final progressValue = progress / 100;
    final iconColor = _iconColor;

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: () => _openDetails(context),
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(16),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      course.title,
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
                    const SizedBox(height: 5),
                    Text(
                      course.subtitle,
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
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text(
                          '$progress%',
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              minHeight: 7,
                              value: progressValue,
                              color: iconColor,
                              backgroundColor: AppColors.surfaceMuted,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${course.lessonsCount} درس',
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              _CourseVisual(
                imageUrl: course.coverImageUrl,
                icon: _icon,
                color: iconColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CourseVisual extends StatelessWidget {
  const _CourseVisual({
    required this.imageUrl,
    required this.icon,
    required this.color,
  });

  final String imageUrl;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return _CourseIcon(
        icon: icon,
        color: color,
      );
    }

    return Container(
      width: 60,
      height: 60,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.10),
        ),
      ),
      child: Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          return _CourseIcon(
            icon: icon,
            color: color,
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) {
            return child;
          }

          return Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                color: color,
                strokeWidth: 2,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CourseIcon extends StatelessWidget {
  const _CourseIcon({
    required this.icon,
    required this.color,
  });

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.10),
        ),
      ),
      child: Icon(
        icon,
        color: color,
        size: 30,
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
          child: Icon(
            icon,
            color: AppColors.text,
            size: 20,
          ),
        ),
      ),
    );
  }
}
