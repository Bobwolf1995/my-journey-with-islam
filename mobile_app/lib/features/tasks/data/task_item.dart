class TaskItem {
  const TaskItem({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.points,
    required this.isCompleted,
  });

  final int id;
  final String title;
  final String description;
  final String type;
  final int points;
  final bool isCompleted;

  factory TaskItem.fallback({
    required int id,
    required String title,
    required String description,
    required String type,
    required int points,
    required bool isCompleted,
  }) {
    return TaskItem(
      id: id,
      title: title,
      description: description,
      type: type,
      points: points,
      isCompleted: isCompleted,
    );
  }

  factory TaskItem.fromJson(Map<String, dynamic> json) {
    return TaskItem(
      id: _int(json['id'], fallback: 0),
      title: _string(
        json['title_ar'] ?? json['name_ar'] ?? json['title'] ?? json['name'],
        fallback: 'مهمة يومية',
      ),
      description: _string(
        json['description_ar'] ??
            json['short_description_ar'] ??
            json['description'] ??
            json['summary'],
        fallback: 'مهمة تساعدك على الاستمرار.',
      ),
      type: _string(
        json['task_type'] ?? json['type'] ?? json['category'],
        fallback: 'daily',
      ),
      points: _int(
        json['points'] ?? json['reward_points'] ?? json['score'],
        fallback: 0,
      ),
      isCompleted: _isCompleted(json),
    );
  }

  TaskItem copyWith({
    bool? isCompleted,
  }) {
    return TaskItem(
      id: id,
      title: title,
      description: description,
      type: type,
      points: points,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  static bool _isCompleted(Map<String, dynamic> json) {
    if (json['is_completed'] == true ||
        json['completed'] == true ||
        json['isCompleted'] == true ||
        json['status'] == 'completed') {
      return true;
    }

    final userTask = json['user_task'];

    if (userTask is Map<String, dynamic>) {
      return userTask['status'] == 'completed' ||
          userTask['is_completed'] == true ||
          userTask['completed'] == true;
    }

    final userTasks = json['user_tasks'];

    if (userTasks is List) {
      return userTasks.any((task) {
        if (task is! Map<String, dynamic>) {
          return false;
        }

        return task['status'] == 'completed' ||
            task['is_completed'] == true ||
            task['completed'] == true;
      });
    }

    return false;
  }
}

class TasksResult {
  const TasksResult({
    required this.tasks,
  });

  final List<TaskItem> tasks;

  int get completedCount {
    return tasks.where((task) => task.isCompleted).length;
  }

  factory TasksResult.fallback() {
    return TasksResult(
      tasks: [
        TaskItem.fallback(
          id: 0,
          title: 'شاهد الدرس الرابع',
          description: 'أكمل مشاهدة درس اليوم.',
          type: 'lesson',
          points: 15,
          isCompleted: true,
        ),
        TaskItem.fallback(
          id: 0,
          title: 'أجب على الاختبار',
          description: 'اختبر فهمك للدرس.',
          type: 'quiz',
          points: 20,
          isCompleted: true,
        ),
        TaskItem.fallback(
          id: 0,
          title: 'اقرأ ملخص الدرس',
          description: 'راجع أهم نقاط الدرس.',
          type: 'reading',
          points: 10,
          isCompleted: false,
        ),
        TaskItem.fallback(
          id: 0,
          title: 'تواصل مع مرشدك',
          description: 'اطرح سؤالا أو شارك تقدمك.',
          type: 'mentor',
          points: 15,
          isCompleted: false,
        ),
        TaskItem.fallback(
          id: 0,
          title: 'صلاة الفجر في وقتها',
          description: 'حافظ على بداية يومك.',
          type: 'worship',
          points: 5,
          isCompleted: true,
        ),
      ],
    );
  }

  factory TasksResult.fromResponse(Map<String, dynamic> response) {
    final items = _extractItems(response['data']);

    final tasks = items
        .whereType<Map<String, dynamic>>()
        .map(TaskItem.fromJson)
        .where((task) => task.id > 0)
        .toList();

    if (tasks.isEmpty) {
      return TasksResult.fallback();
    }

    return TasksResult(tasks: tasks);
  }

  static List<dynamic> _extractItems(dynamic data) {
    if (data is List) {
      return data;
    }

    if (data is Map<String, dynamic>) {
      final directData = data['data'];
      final tasks = data['tasks'];
      final items = data['items'];

      if (directData is List) {
        return directData;
      }

      if (tasks is List) {
        return tasks;
      }

      if (items is List) {
        return items;
      }

      if (directData is Map<String, dynamic>) {
        return _extractItems(directData);
      }
    }

    return <dynamic>[];
  }
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
