class HomeDashboard {
  const HomeDashboard({
    required this.user,
    required this.progress,
    required this.nextLesson,
    required this.dailyTasks,
    required this.unreadNotificationsCount,
  });

  final HomeUser user;
  final HomeProgress progress;
  final NextLesson nextLesson;
  final List<DailyTask> dailyTasks;
  final int unreadNotificationsCount;

  int get completedTasksCount {
    return dailyTasks.where((task) => task.isCompleted).length;
  }

  factory HomeDashboard.fallback() {
    return const HomeDashboard(
      user: HomeUser(
        name: 'أحمد محمد',
        rank: 'طالب علم',
        totalPoints: 650,
      ),
      progress: HomeProgress(
        percentage: 65,
        currentLevel: 'المستوى 2',
        message: 'أنت على الطريق الصحيح',
      ),
      nextLesson: NextLesson(
        id: 1,
        title: 'الدرس 4: أركان الإسلام',
        courseTitle: 'مدخل إلى الإسلام',
      ),
      dailyTasks: [
        DailyTask(
          id: 1,
          title: 'شاهد الدرس الرابع',
          points: 15,
          isCompleted: true,
        ),
        DailyTask(
          id: 2,
          title: 'أجب على الاختبار',
          points: 20,
          isCompleted: true,
        ),
        DailyTask(
          id: 3,
          title: 'اقرأ ملخص الدرس',
          points: 10,
          isCompleted: false,
        ),
        DailyTask(
          id: 4,
          title: 'تواصل مع مرشدك',
          points: 15,
          isCompleted: false,
        ),
        DailyTask(
          id: 5,
          title: 'صلاة الفجر في وقتها',
          points: 5,
          isCompleted: true,
        ),
      ],
      unreadNotificationsCount: 2,
    );
  }

  factory HomeDashboard.fromResponse(Map<String, dynamic> response) {
    final data = response['data'];

    if (data is! Map<String, dynamic>) {
      return HomeDashboard.fallback();
    }

    final tasks = data['daily_tasks'];

    return HomeDashboard(
      user: HomeUser.fromJson(_map(data['user'])),
      progress: HomeProgress.fromJson(_map(data['progress'])),
      nextLesson: NextLesson.fromJson(_map(data['next_lesson'])),
      dailyTasks: tasks is List
          ? tasks
              .whereType<Map<String, dynamic>>()
              .map(DailyTask.fromJson)
              .toList()
          : HomeDashboard.fallback().dailyTasks,
      unreadNotificationsCount: _int(
        data['unread_notifications_count'],
        fallback: 0,
      ),
    );
  }

  static Map<String, dynamic> _map(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    return <String, dynamic>{};
  }

  static int _int(dynamic value, {required int fallback}) {
    if (value is int) {
      return value;
    }

    if (value is String) {
      return int.tryParse(value) ?? fallback;
    }

    return fallback;
  }
}

class HomeUser {
  const HomeUser({
    required this.name,
    required this.rank,
    required this.totalPoints,
  });

  final String name;
  final String rank;
  final int totalPoints;

  factory HomeUser.fromJson(Map<String, dynamic> json) {
    return HomeUser(
      name: _string(json['name'], fallback: 'أحمد محمد'),
      rank: _string(json['rank'], fallback: 'طالب علم'),
      totalPoints: _int(json['total_points'], fallback: 650),
    );
  }
}

class HomeProgress {
  const HomeProgress({
    required this.percentage,
    required this.currentLevel,
    required this.message,
  });

  final int percentage;
  final String currentLevel;
  final String message;

  factory HomeProgress.fromJson(Map<String, dynamic> json) {
    return HomeProgress(
      percentage: _int(json['percentage'], fallback: 65),
      currentLevel: _string(json['current_level'], fallback: 'المستوى 2'),
      message: _string(json['message'], fallback: 'أنت على الطريق الصحيح'),
    );
  }
}

class NextLesson {
  const NextLesson({
    required this.id,
    required this.title,
    required this.courseTitle,
  });

  final int id;
  final String title;
  final String courseTitle;

  factory NextLesson.fromJson(Map<String, dynamic> json) {
    return NextLesson(
      id: _int(json['id'], fallback: 1),
      title: _string(json['title'], fallback: 'الدرس 4: أركان الإسلام'),
      courseTitle: _string(json['course_title'], fallback: 'مدخل إلى الإسلام'),
    );
  }
}

class DailyTask {
  const DailyTask({
    required this.id,
    required this.title,
    required this.points,
    required this.isCompleted,
  });

  final int id;
  final String title;
  final int points;
  final bool isCompleted;

  factory DailyTask.fromJson(Map<String, dynamic> json) {
    return DailyTask(
      id: _int(json['id'], fallback: 0),
      title: _string(json['title'], fallback: 'مهمة يومية'),
      points: _int(json['points'], fallback: 0),
      isCompleted: json['is_completed'] == true,
    );
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

  if (value is String) {
    return int.tryParse(value) ?? fallback;
  }

  return fallback;
}
