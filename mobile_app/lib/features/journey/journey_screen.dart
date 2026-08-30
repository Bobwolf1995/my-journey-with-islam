import 'package:flutter/material.dart';

import '../../shared/theme/app_colors.dart';
import '../courses/presentation/courses_page.dart';

class JourneyScreen extends StatelessWidget {
  const JourneyScreen({super.key});

  Future<void> _openCoursesPage(
    BuildContext context, {
    required String pathTitle,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CoursesPage(
          initialPathTitle: pathTitle,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _JourneyHeader(),
                const SizedBox(height: 18),
                const _ProgressOverview(),
                const SizedBox(height: 22),
                const _SectionTitle(title: 'مسارات رحلتك'),
                const SizedBox(height: 12),
                _TrackCard(
                  icon: Icons.account_balance_rounded,
                  title: 'المسار الأساسي',
                  subtitle: 'تعلم أساسيات الإسلام خطوة بخطوة',
                  lessons: '12 درس',
                  progress: 65,
                  color: AppColors.primary,
                  onTap: () => _openCoursesPage(
                    context,
                    pathTitle: 'المسار الأساسي',
                  ),
                ),
                const SizedBox(height: 12),
                _TrackCard(
                  icon: Icons.auto_awesome_rounded,
                  title: 'العقيدة',
                  subtitle: 'بناء الإيمان والفهم الصحيح',
                  lessons: '8 دروس',
                  progress: 40,
                  color: const Color(0xFF6D5EA8),
                  onTap: () => _openCoursesPage(
                    context,
                    pathTitle: 'العقيدة',
                  ),
                ),
                const SizedBox(height: 12),
                _TrackCard(
                  icon: Icons.mosque_rounded,
                  title: 'العبادات',
                  subtitle: 'الصلاة والطهارة والعبادات اليومية',
                  lessons: '10 دروس',
                  progress: 30,
                  color: const Color(0xFF2C7DA0),
                  onTap: () => _openCoursesPage(
                    context,
                    pathTitle: 'العبادات',
                  ),
                ),
                const SizedBox(height: 12),
                _TrackCard(
                  icon: Icons.menu_book_rounded,
                  title: 'السيرة النبوية',
                  subtitle: 'تعرف على حياة النبي صلى الله عليه وسلم',
                  lessons: '8 دروس',
                  progress: 25,
                  color: AppColors.secondary,
                  onTap: () => _openCoursesPage(
                    context,
                    pathTitle: 'السيرة النبوية',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _JourneyHeader extends StatelessWidget {
  const _JourneyHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _CircleButton(
          icon: Icons.arrow_back_ios_new_rounded,
          onTap: () {
            Navigator.of(context).pop();
          },
        ),
        const Spacer(),
        const Text(
          'رحلتي',
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

class _ProgressOverview extends StatelessWidget {
  const _ProgressOverview();

  @override
  Widget build(BuildContext context) {
    return Container(
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
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.16),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: const Row(
        children: [
          _OverviewIcon(),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'تقدم رحلتك',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    height: 1.3,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 7),
                Text(
                  'أكملت 12 درسًا وجمعت 650 نقطة حتى الآن.',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.55,
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

class _OverviewIcon extends StatelessWidget {
  const _OverviewIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.18),
        ),
      ),
      child: const Icon(
        Icons.route_rounded,
        color: Colors.white,
        size: 31,
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

class _TrackCard extends StatelessWidget {
  const _TrackCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.lessons,
    required this.progress,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String lessons;
  final int progress;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final progressValue = (progress / 100).clamp(0.0, 1.0);

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
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
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                        height: 1.45,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 13),
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
                              value: progressValue,
                              minHeight: 7,
                              backgroundColor: AppColors.surfaceMuted,
                              valueColor: AlwaysStoppedAnimation<Color>(color),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          lessons,
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
              Container(
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
                  size: 29,
                ),
              ),
            ],
          ),
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
