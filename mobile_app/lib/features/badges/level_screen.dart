import 'package:flutter/material.dart';

import '../../shared/theme/app_colors.dart';
import 'data/badge_item.dart';
import 'data/badges_service.dart';

class LevelScreen extends StatefulWidget {
  const LevelScreen({super.key});

  @override
  State<LevelScreen> createState() => _LevelScreenState();
}

class _LevelScreenState extends State<LevelScreen> {
  final BadgesService _badgesService = BadgesService();

  late Future<BadgesResult> _badgesFuture;

  @override
  void initState() {
    super.initState();
    _badgesFuture = _badgesService.getMyBadges();
  }

  void _refresh() {
    setState(() {
      _badgesFuture = _badgesService.getMyBadges();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: FutureBuilder<BadgesResult>(
            future: _badgesFuture,
            builder: (context, snapshot) {
              final result = snapshot.data;
              final badges = result?.badges ?? const <BadgeItem>[];
              final totalPoints = badges.fold<int>(
                0,
                (sum, badge) => sum + badge.points,
              );
              final level = _levelFromPoints(totalPoints);
              final nextLevelPoints = _nextLevelPoints(level);
              final currentLevelStart = _levelStartPoints(level);
              final progress = nextLevelPoints <= currentLevelStart
                  ? 1.0
                  : ((totalPoints - currentLevelStart) /
                          (nextLevelPoints - currentLevelStart))
                      .clamp(0.0, 1.0);

              if (snapshot.connectionState != ConnectionState.done &&
                  result == null) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                  ),
                );
              }

              return RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () async {
                  _refresh();
                  await _badgesFuture;
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _Header(
                        onBack: () {
                          Navigator.maybePop(context);
                        },
                        onRefresh: _refresh,
                      ),
                      const SizedBox(height: 18),
                      _LevelHero(
                        level: level,
                        totalPoints: totalPoints,
                        progress: progress,
                        nextLevelPoints: nextLevelPoints,
                      ),
                      const SizedBox(height: 16),
                      _StatsRow(
                        badgesCount: badges.length,
                        totalPoints: totalPoints,
                      ),
                      const SizedBox(height: 18),
                      const _SectionTitle(title: 'الأوسمة المكتسبة'),
                      const SizedBox(height: 10),
                      if (badges.isEmpty)
                        const _EmptyCard()
                      else
                        ...badges.map(
                          (badge) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _BadgeTile(badge: badge),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  int _levelFromPoints(int points) {
    if (points >= 1000) {
      return 6;
    }

    if (points >= 700) {
      return 5;
    }

    if (points >= 450) {
      return 4;
    }

    if (points >= 250) {
      return 3;
    }

    if (points >= 100) {
      return 2;
    }

    return 1;
  }

  int _levelStartPoints(int level) {
    switch (level) {
      case 6:
        return 1000;
      case 5:
        return 700;
      case 4:
        return 450;
      case 3:
        return 250;
      case 2:
        return 100;
      default:
        return 0;
    }
  }

  int _nextLevelPoints(int level) {
    switch (level) {
      case 1:
        return 100;
      case 2:
        return 250;
      case 3:
        return 450;
      case 4:
        return 700;
      case 5:
        return 1000;
      default:
        return 1000;
    }
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.onBack,
    required this.onRefresh,
  });

  final VoidCallback onBack;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _CircleButton(
          icon: Icons.refresh_rounded,
          onTap: onRefresh,
        ),
        const Spacer(),
        const Text(
          'المستوى',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.text,
            fontSize: 28,
            fontWeight: FontWeight.w900,
          ),
        ),
        const Spacer(),
        _CircleButton(
          icon: Icons.arrow_forward_ios_rounded,
          onTap: onBack,
        ),
      ],
    );
  }
}

class _LevelHero extends StatelessWidget {
  const _LevelHero({
    required this.level,
    required this.totalPoints,
    required this.progress,
    required this.nextLevelPoints,
  });

  final int level;
  final int totalPoints;
  final double progress;
  final int nextLevelPoints;

  @override
  Widget build(BuildContext context) {
    final remaining = (nextLevelPoints - totalPoints).clamp(0, nextLevelPoints);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.18),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  color: Colors.white,
                  size: 42,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'المستوى $level',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$totalPoints نقطة مكتسبة',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: Colors.white.withValues(alpha: 0.18),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            remaining == 0
                ? 'وصلت إلى أعلى مستوى حاليًا'
                : 'باقي $remaining نقطة للمستوى التالي',
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.badgesCount,
    required this.totalPoints,
  });

  final int badgesCount;
  final int totalPoints;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.emoji_events_rounded,
            title: 'الأوسمة',
            value: badgesCount.toString(),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            icon: Icons.star_rounded,
            title: 'النقاط',
            value: totalPoints.toString(),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 112,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: AppColors.primary,
            size: 28,
          ),
          const Spacer(),
          Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            textAlign: TextAlign.right,
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

class _BadgeTile extends StatelessWidget {
  const _BadgeTile({
    required this.badge,
  });

  final BadgeItem badge;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.emoji_events_rounded,
              color: AppColors.primary,
              size: 30,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  badge.title,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  badge.description.isEmpty
                      ? 'وسام ضمن تقدمك في الرحلة.'
                      : badge.description,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '+${badge.points}',
            style: const TextStyle(
              color: AppColors.secondary,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
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
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: const Text(
        'لا توجد أوسمة بعد. أكمل الدروس والمهام لتحصل على أوسمتك.',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: AppColors.textMuted,
          fontSize: 14,
          height: 1.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    this.onTap,
  });

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
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
