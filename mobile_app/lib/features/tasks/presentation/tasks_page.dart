import 'package:flutter/material.dart';

import '../../../shared/theme/app_colors.dart';
import '../data/task_item.dart';
import '../data/tasks_service.dart';

class TasksPage extends StatefulWidget {
  const TasksPage({super.key});

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  final TasksService _tasksService = TasksService();

  late Future<TasksResult> _tasksFuture;
  List<TaskItem>? _tasks;

  final Set<int> _sendingTaskIds = <int>{};

  @override
  void initState() {
    super.initState();
    _tasksFuture = _loadTasks();
  }

  Future<TasksResult> _loadTasks() async {
    final result = await _tasksService.getTasks();
    _tasks = result.tasks;
    return result;
  }

  Future<void> _refresh() async {
    setState(() {
      _tasksFuture = _loadTasks();
    });

    await _tasksFuture;
  }

  Future<void> _completeTask(TaskItem task) async {
    if (task.isCompleted || _sendingTaskIds.contains(task.id)) {
      return;
    }

    if (task.id <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'هذه المهمة تجريبية ولا يمكن إرسالها للسيرفر الآن',
            textAlign: TextAlign.right,
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() {
      _sendingTaskIds.add(task.id);
    });

    final response = await _tasksService.completeTask(taskId: task.id);

    if (!mounted) {
      return;
    }

    final isSuccess = response['success'] == true;

    setState(() {
      _sendingTaskIds.remove(task.id);

      if (isSuccess) {
        _tasks = (_tasks ?? <TaskItem>[])
            .map(
              (item) =>
                  item.id == task.id ? item.copyWith(isCompleted: true) : item,
            )
            .toList();
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isSuccess
              ? 'تم إكمال المهمة بنجاح'
              : response['message']?.toString() ?? 'تعذر إكمال المهمة الآن',
          textAlign: TextAlign.right,
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isSuccess ? AppColors.primary : AppColors.danger,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: FutureBuilder<TasksResult>(
        future: _tasksFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              _tasks == null) {
            return const SafeArea(
              child: _LoadingView(),
            );
          }

          final fallbackTasks =
              snapshot.data?.tasks ?? TasksResult.fallback().tasks;
          final tasks = _tasks ?? fallbackTasks;
          final completedCount = tasks.where((task) => task.isCompleted).length;

          return SafeArea(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _refresh,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
                child: Column(
                  children: [
                    _TasksHeader(onRefresh: _refresh),
                    const SizedBox(height: 18),
                    _ProgressSummary(
                      completed: completedCount,
                      total: tasks.length,
                    ),
                    const SizedBox(height: 18),
                    if (tasks.isEmpty)
                      const _EmptyTasksCard()
                    else
                      _TasksCard(
                        tasks: tasks,
                        sendingTaskIds: _sendingTaskIds,
                        onComplete: _completeTask,
                      ),
                    const SizedBox(height: 18),
                    const _RewardCard(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TasksHeader extends StatelessWidget {
  const _TasksHeader({
    required this.onRefresh,
  });

  final Future<void> Function() onRefresh;

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
          'مهامي',
          style: TextStyle(
            color: AppColors.text,
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
        const Spacer(),
        _CircleButton(
          icon: Icons.refresh_rounded,
          onTap: () {
            onRefresh();
          },
        ),
      ],
    );
  }
}

class _ProgressSummary extends StatelessWidget {
  const _ProgressSummary({
    required this.completed,
    required this.total,
  });

  final int completed;
  final int total;

  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : completed / total;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$completed/$total مكتملة',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const Spacer(),
              const Text(
                'مهام اليوم',
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppColors.surfaceMuted,
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            completed == total && total > 0
                ? 'أحسنت، أنهيت مهام اليوم.'
                : 'أكمل مهامك اليومية لتزيد تقدمك.',
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

class _TasksCard extends StatelessWidget {
  const _TasksCard({
    required this.tasks,
    required this.sendingTaskIds,
    required this.onComplete,
  });

  final List<TaskItem> tasks;
  final Set<int> sendingTaskIds;
  final ValueChanged<TaskItem> onComplete;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          for (var index = 0; index < tasks.length; index++)
            _TaskRow(
              task: tasks[index],
              isSending: sendingTaskIds.contains(tasks[index].id),
              isLast: index == tasks.length - 1,
              onTap: () => onComplete(tasks[index]),
            ),
        ],
      ),
    );
  }
}

class _TaskRow extends StatelessWidget {
  const _TaskRow({
    required this.task,
    required this.isSending,
    required this.onTap,
    this.isLast = false,
  });

  final TaskItem task;
  final bool isSending;
  final VoidCallback onTap;
  final bool isLast;

  IconData get _typeIcon {
    final type = task.type.toLowerCase();

    if (type.contains('quiz') || task.title.contains('اختبار')) {
      return Icons.quiz_rounded;
    }

    if (type.contains('reading') || task.title.contains('اقرأ')) {
      return Icons.menu_book_rounded;
    }

    if (type.contains('mentor') || task.title.contains('مرشد')) {
      return Icons.chat_bubble_outline_rounded;
    }

    if (type.contains('worship') || task.title.contains('صلاة')) {
      return Icons.mosque_rounded;
    }

    return Icons.play_arrow_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final canComplete = task.id > 0 && !task.isCompleted && !isSending;

    return InkWell(
      onTap: canComplete ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : const Border(
                  bottom: BorderSide(color: AppColors.border),
                ),
        ),
        child: Row(
          children: [
            if (isSending)
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: AppColors.primary,
                ),
              )
            else
              Icon(
                task.isCompleted
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color:
                    task.isCompleted ? AppColors.primary : AppColors.textMuted,
                size: 24,
              ),
            const SizedBox(width: 12),
            Text(
              '${task.points} نقطة',
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    task.title,
                    textAlign: TextAlign.right,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: task.isCompleted
                          ? AppColors.textMuted
                          : AppColors.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      decoration:
                          task.isCompleted ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    task.description,
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: task.isCompleted
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                _typeIcon,
                color: AppColors.primary,
                size: 21,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RewardCard extends StatelessWidget {
  const _RewardCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 116,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: const BoxDecoration(
              color: AppColors.secondary,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.card_giftcard_rounded,
              color: Colors.white,
              size: 34,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'مكافأة إكمال المهام',
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'أكمل جميع مهام اليوم لتحصل على نقاط إضافية.',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    height: 1.4,
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

class _EmptyTasksCard extends StatelessWidget {
  const _EmptyTasksCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.task_alt_rounded,
            color: AppColors.textMuted,
            size: 42,
          ),
          SizedBox(height: 12),
          Text(
            'لا توجد مهام حاليًا',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.text,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'عندما تتوفر مهام جديدة ستظهر هنا.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 13,
              height: 1.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon, color: AppColors.text, size: 20),
      ),
    );
  }
}
