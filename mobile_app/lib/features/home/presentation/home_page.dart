import 'package:flutter/material.dart';

import '../../../core/network/api_health_service.dart';
import '../../../shared/theme/app_colors.dart';
import '../../ai_assistant/presentation/ai_assistant_screen.dart';
import '../../chat/presentation/conversations_screen.dart';
import '../../courses/presentation/lesson_details_page.dart';
import '../../notifications/presentation/notifications_page.dart';
import '../../tasks/data/tasks_service.dart';
import '../../tasks/presentation/tasks_page.dart';
import '../data/home_dashboard.dart';
import '../data/home_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    this.onOpenProfile,
  });

  final VoidCallback? onOpenProfile;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final HomeService _homeService = HomeService();
  final TasksService _tasksService = TasksService();

  late Future<HomeDashboard> _dashboardFuture;

  final Set<int> _completedTaskIds = <int>{};
  final Set<int> _sendingTaskIds = <int>{};

  @override
  void initState() {
    super.initState();
    _dashboardFuture = _homeService.getDashboard();
  }

  Future<void> _refresh() async {
    setState(() {
      _dashboardFuture = _homeService.getDashboard();
    });

    await _dashboardFuture;
  }

  bool _isTaskCompleted(DailyTask task) {
    return task.isCompleted || _completedTaskIds.contains(task.id);
  }

  bool _opensMentor(DailyTask task) {
    return task.title.contains('مرشد');
  }

  Future<void> _handleTaskTap(DailyTask task) async {
    if (_opensMentor(task)) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const ConversationsScreen(),
        ),
      );
      return;
    }

    if (_isTaskCompleted(task) || _sendingTaskIds.contains(task.id)) {
      return;
    }

    setState(() {
      _sendingTaskIds.add(task.id);
    });

    final response = await _tasksService.completeTask(taskId: task.id);

    if (!mounted) {
      return;
    }

    final success = response['success'] == true;

    setState(() {
      _sendingTaskIds.remove(task.id);

      if (success) {
        _completedTaskIds.add(task.id);
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'تم إكمال المهمة بنجاح'
              : response['message']?.toString() ?? 'تعذر إكمال المهمة الآن',
          textAlign: TextAlign.right,
        ),
        backgroundColor: success ? AppColors.primary : AppColors.danger,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: FutureBuilder<HomeDashboard>(
          future: _dashboardFuture,
          builder: (context, snapshot) {
            final dashboard = snapshot.data ?? HomeDashboard.fallback();
            final visibleTasks = dashboard.dailyTasks.isEmpty
                ? HomeDashboard.fallback().dailyTasks
                : dashboard.dailyTasks;

            final completedCount =
                visibleTasks.where((task) => _isTaskCompleted(task)).length;

            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _refresh,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _HomeHeader(
                      dashboard: dashboard,
                      onOpenProfile: widget.onOpenProfile,
                      onNotificationsChanged: _refresh,
                    ),
                    const SizedBox(height: 18),
                    _TodayJourneyCard(dashboard: dashboard),
                    const SizedBox(height: 14),
                    _NextLessonCard(lesson: dashboard.nextLesson),
                    const SizedBox(height: 14),
                    const _AiAssistantShortcut(),
                    const SizedBox(height: 12),
                    const Align(
                      alignment: Alignment.centerRight,
                      child: _ApiStatusPill(),
                    ),
                    const SizedBox(height: 24),
                    _SectionTitle(
                      completed: completedCount,
                      total: visibleTasks.length,
                    ),
                    const SizedBox(height: 12),
                    _DailyTasksCard(
                      tasks: visibleTasks,
                      completedTaskIds: _completedTaskIds,
                      sendingTaskIds: _sendingTaskIds,
                      onTaskTap: _handleTaskTap,
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

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.dashboard,
    required this.onNotificationsChanged,
    this.onOpenProfile,
  });

  final HomeDashboard dashboard;
  final VoidCallback? onOpenProfile;
  final Future<void> Function() onNotificationsChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _CircleButton(
          icon: Icons.person_outline_rounded,
          onTap: onOpenProfile ?? () {},
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'السلام عليكم',
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 13,
                  height: 1.2,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                dashboard.user.name,
                textAlign: TextAlign.right,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 23,
                  height: 1.2,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _NotificationButton(
          unreadCount: dashboard.unreadNotificationsCount,
          onNotificationsChanged: onNotificationsChanged,
        ),
      ],
    );
  }
}

class _TodayJourneyCard extends StatelessWidget {
  const _TodayJourneyCard({
    required this.dashboard,
  });

  final HomeDashboard dashboard;

  @override
  Widget build(BuildContext context) {
    final percentage = dashboard.progress.percentage.clamp(0, 100);
    final progressValue = percentage / 100;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            AppColors.primaryDark,
            AppColors.primary,
          ],
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.16),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ProgressRing(percentage: percentage),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.13),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.12),
                        ),
                      ),
                      child: Text(
                        dashboard.progress.currentLevel,
                        textAlign: TextAlign.right,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.secondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'رحلتك اليوم',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        height: 1.2,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      dashboard.progress.message,
                      textAlign: TextAlign.right,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.84),
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
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progressValue,
              minHeight: 9,
              backgroundColor: Colors.white.withValues(alpha: 0.18),
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                '$percentage%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              Text(
                'تقدمك مستمر خطوة بخطوة',
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.72),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProgressRing extends StatelessWidget {
  const _ProgressRing({
    required this.percentage,
  });

  final int percentage;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 86,
      height: 86,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 86,
            height: 86,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.12),
              ),
            ),
          ),
          SizedBox(
            width: 70,
            height: 70,
            child: CircularProgressIndicator(
              value: percentage / 100,
              strokeWidth: 7,
              backgroundColor: Colors.white.withValues(alpha: 0.18),
              color: AppColors.secondary,
              strokeCap: StrokeCap.round,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$percentage%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  height: 1.05,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'مكتمل',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.70),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NotificationButton extends StatelessWidget {
  const _NotificationButton({
    required this.onNotificationsChanged,
    this.unreadCount = 0,
  });

  final int unreadCount;
  final Future<void> Function() onNotificationsChanged;

  Future<void> _openNotifications(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const NotificationsPage(),
      ),
    );

    if (context.mounted) {
      await onNotificationsChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _openNotifications(context),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.surfaceSoft,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.borderSoft),
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                color: AppColors.text,
                size: 23,
              ),
            ),
            if (unreadCount > 0)
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.background,
                      width: 2,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ApiStatusPill extends StatelessWidget {
  const _ApiStatusPill();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: ApiHealthService().check(),
      builder: (context, snapshot) {
        final isConnected = snapshot.data == true;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
          decoration: BoxDecoration(
            color:
                isConnected ? AppColors.primaryLight : AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color:
                  isConnected ? AppColors.primaryLight : AppColors.borderSoft,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isConnected
                    ? Icons.cloud_done_outlined
                    : Icons.cloud_off_outlined,
                color: isConnected ? AppColors.primary : AppColors.textMuted,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                isConnected ? 'متصل بالسيرفر' : 'غير متصل بالسيرفر',
                style: TextStyle(
                  color: isConnected ? AppColors.primary : AppColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _NextLessonCard extends StatelessWidget {
  const _NextLessonCard({
    required this.lesson,
  });

  final NextLesson lesson;

  void _openLesson(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LessonDetailsPage(lessonId: lesson.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: () => _openLesson(context),
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
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.16),
                      blurRadius: 14,
                      offset: const Offset(0, 7),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'تابع التعلم',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      lesson.title,
                      textAlign: TextAlign.right,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 18,
                        height: 1.35,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      lesson.courseTitle,
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
              const SizedBox(width: 14),
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: AppColors.secondaryLight,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.borderSoft),
                ),
                child: const Icon(
                  Icons.menu_book_rounded,
                  color: AppColors.secondary,
                  size: 32,
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
  const _SectionTitle({
    required this.completed,
    required this.total,
  });

  final int completed;
  final int total;

  void _openTasks(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const TasksPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasRemainingTasks = completed < total;

    return InkWell(
      onTap: () => _openTasks(context),
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            _TaskProgressBadge(
              completed: completed,
              total: total,
              hasRemainingTasks: hasRemainingTasks,
            ),
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _TaskPulseIcon(active: hasRemainingTasks),
                    const SizedBox(width: 9),
                    const Text(
                      'مهام اليوم',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: AppColors.text,
                        fontSize: 23,
                        height: 1.15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  hasRemainingTasks
                      ? 'خطوات بسيطة تثبّت رحلتك اليومية'
                      : 'أحسنت، أنجزت مهام اليوم',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    height: 1.25,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskProgressBadge extends StatelessWidget {
  const _TaskProgressBadge({
    required this.completed,
    required this.total,
    required this.hasRemainingTasks,
  });

  final int completed;
  final int total;
  final bool hasRemainingTasks;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
      decoration: BoxDecoration(
        color: hasRemainingTasks
            ? AppColors.primaryLight
            : AppColors.secondaryLight,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$completed/$total',
            style: TextStyle(
              color:
                  hasRemainingTasks ? AppColors.primary : AppColors.secondary,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 6),
          Icon(
            hasRemainingTasks ? Icons.flag_rounded : Icons.check_circle_rounded,
            color: hasRemainingTasks ? AppColors.primary : AppColors.secondary,
            size: 17,
          ),
        ],
      ),
    );
  }
}

class _TaskPulseIcon extends StatefulWidget {
  const _TaskPulseIcon({
    required this.active,
  });

  final bool active;

  @override
  State<_TaskPulseIcon> createState() => _TaskPulseIconState();
}

class _TaskPulseIconState extends State<_TaskPulseIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _glow;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    );

    _scale = Tween<double>(begin: 0.92, end: 1.14).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _glow = Tween<double>(begin: 0.14, end: 0.32).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    if (widget.active) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant _TaskPulseIcon oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.active && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }

    if (!widget.active && _controller.isAnimating) {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active) {
      return Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: AppColors.secondaryLight,
          borderRadius: BorderRadius.circular(13),
        ),
        child: const Icon(
          Icons.check_rounded,
          color: AppColors.secondary,
          size: 20,
        ),
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scale.value,
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.secondaryLight,
              borderRadius: BorderRadius.circular(13),
              boxShadow: [
                BoxShadow(
                  color: AppColors.secondary.withValues(alpha: _glow.value),
                  blurRadius: 18,
                  spreadRadius: 1,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(
              Icons.task_alt_rounded,
              color: AppColors.secondary,
              size: 20,
            ),
          ),
        );
      },
    );
  }
}

class _DailyTasksCard extends StatelessWidget {
  const _DailyTasksCard({
    required this.tasks,
    required this.completedTaskIds,
    required this.sendingTaskIds,
    required this.onTaskTap,
  });

  final List<DailyTask> tasks;
  final Set<int> completedTaskIds;
  final Set<int> sendingTaskIds;
  final ValueChanged<DailyTask> onTaskTap;

  bool _isCompleted(DailyTask task) {
    return task.isCompleted || completedTaskIds.contains(task.id);
  }

  @override
  Widget build(BuildContext context) {
    final visibleTasks =
        tasks.isEmpty ? HomeDashboard.fallback().dailyTasks : tasks;

    return Container(
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
        children: [
          for (var index = 0; index < visibleTasks.length; index++)
            _TaskRow(
              task: visibleTasks[index],
              isLast: index == visibleTasks.length - 1,
              isCompleted: _isCompleted(visibleTasks[index]),
              isSending: sendingTaskIds.contains(visibleTasks[index].id),
              onTap: () => onTaskTap(visibleTasks[index]),
            ),
        ],
      ),
    );
  }
}

class _TaskRow extends StatelessWidget {
  const _TaskRow({
    required this.task,
    required this.isLast,
    required this.isCompleted,
    required this.isSending,
    required this.onTap,
  });

  final DailyTask task;
  final bool isLast;
  final bool isCompleted;
  final bool isSending;
  final VoidCallback onTap;

  bool get _opensMentor {
    return task.title.contains('مرشد');
  }

  IconData get _taskIcon {
    if (task.title.contains('اختبار')) {
      return Icons.quiz_rounded;
    }

    if (task.title.contains('اقرأ') || task.title.contains('ملخص')) {
      return Icons.menu_book_rounded;
    }

    if (task.title.contains('مرشد')) {
      return Icons.chat_bubble_outline_rounded;
    }

    if (task.title.contains('صلاة')) {
      return Icons.mosque_rounded;
    }

    return Icons.play_arrow_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isSending ? null : onTap,
      borderRadius: BorderRadius.vertical(
        top: const Radius.circular(24),
        bottom: isLast ? const Radius.circular(24) : Radius.zero,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : const Border(
                  bottom: BorderSide(color: AppColors.borderSoft),
                ),
        ),
        child: Row(
          children: [
            if (isSending)
              const SizedBox(
                width: 25,
                height: 25,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: AppColors.primary,
                ),
              )
            else
              Icon(
                isCompleted
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: isCompleted ? AppColors.primary : AppColors.textSoft,
                size: 25,
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                task.title,
                textAlign: TextAlign.right,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isCompleted ? AppColors.textMuted : AppColors.text,
                  fontSize: 15,
                  height: 1.35,
                  fontWeight: FontWeight.w800,
                  decoration: isCompleted ? TextDecoration.lineThrough : null,
                  decorationColor: AppColors.textMuted,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isCompleted
                    ? AppColors.primaryLight
                    : AppColors.surfaceSoft,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isCompleted
                      ? AppColors.primaryLight
                      : AppColors.borderSoft,
                ),
              ),
              child: Icon(
                _opensMentor ? Icons.arrow_back_ios_new_rounded : _taskIcon,
                color: AppColors.primary,
                size: _opensMentor ? 17 : 22,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AiAssistantShortcut extends StatelessWidget {
  const _AiAssistantShortcut();

  void _openAssistant(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const AiAssistantScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: () => _openAssistant(context),
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(16),
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
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: AppColors.primary,
                  size: 25,
                ),
              ),
              const SizedBox(width: 13),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'تحتاج توجيهًا؟',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: AppColors.text,
                        fontSize: 16,
                        height: 1.3,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'اسأل المساعد الذكي، والأسئلة الحساسة تُحوّل إلى المرشد.',
                      textAlign: TextAlign.right,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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
              const SizedBox(width: 10),
              const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: AppColors.textMuted,
                size: 17,
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
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.surfaceSoft,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderSoft),
          ),
          child: Icon(
            icon,
            color: AppColors.text,
            size: 23,
          ),
        ),
      ),
    );
  }
}
