class CourseSummary {
  const CourseSummary({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.level,
    required this.lessonsCount,
    required this.progress,
    required this.iconName,
    this.coverImageUrl = '',
  });

  final int id;
  final String title;
  final String subtitle;
  final String level;
  final int lessonsCount;
  final int progress;
  final String iconName;
  final String coverImageUrl;

  factory CourseSummary.fallback({
    required int id,
    required String title,
    required String subtitle,
    required String level,
    required int lessonsCount,
    required int progress,
    required String iconName,
    String coverImageUrl = '',
  }) {
    return CourseSummary(
      id: id,
      title: title,
      subtitle: subtitle,
      level: level,
      lessonsCount: lessonsCount,
      progress: progress,
      iconName: iconName,
      coverImageUrl: coverImageUrl,
    );
  }

  factory CourseSummary.fromJson(Map<String, dynamic> json) {
    final learningPath = json['learning_path'] is Map<String, dynamic>
        ? json['learning_path'] as Map<String, dynamic>
        : <String, dynamic>{};

    return CourseSummary(
      id: _int(json['id'], fallback: 0),
      title: _string(
        json['title_ar'] ?? json['title'],
        fallback: 'دورة تعليمية',
      ),
      subtitle: _string(
        json['description_ar'] ??
            json['short_description_ar'] ??
            learningPath['title_ar'] ??
            learningPath['name_ar'],
        fallback: 'مسار تعليمي مناسب لبناء الأساسيات.',
      ),
      level: _string(json['level'], fallback: 'مبتدئ'),
      lessonsCount: _int(
        json['lessons_count'] ?? json['total_lessons'],
        fallback: 0,
      ),
      progress: _int(
        json['progress_percentage'] ?? json['progress'],
        fallback: 0,
      ),
      iconName: _string(
        json['icon'] ?? learningPath['icon'],
        fallback: 'book',
      ),
      coverImageUrl: _string(
        json['cover_image_url'] ??
            json['cover_image'] ??
            json['thumbnail'] ??
            learningPath['cover_image_url'] ??
            learningPath['cover_image'] ??
            learningPath['thumbnail'],
        fallback: '',
      ),
    );
  }
}

class CoursesResult {
  const CoursesResult({
    required this.courses,
    required this.isSuccess,
    required this.message,
  });

  final List<CourseSummary> courses;
  final bool isSuccess;
  final String message;

  bool get hasCourses => courses.isNotEmpty;

  factory CoursesResult.empty({
    String message = 'لا توجد دورات متاحة حاليًا.',
  }) {
    return CoursesResult(
      courses: const [],
      isSuccess: true,
      message: message,
    );
  }

  factory CoursesResult.failure({
    required String message,
  }) {
    return CoursesResult(
      courses: const [],
      isSuccess: false,
      message: _friendlyMessage(
        message,
        fallback: 'تعذر تحميل الدورات الآن',
      ),
    );
  }

  factory CoursesResult.fallback() {
    return CoursesResult(
      isSuccess: true,
      message: '',
      courses: [
        CourseSummary.fallback(
          id: 1,
          title: 'المسار الأساسي',
          subtitle: 'تعلم الأساسيات خطوة بخطوة',
          level: 'مبتدئ',
          lessonsCount: 12,
          progress: 65,
          iconName: 'mosque',
        ),
        CourseSummary.fallback(
          id: 2,
          title: 'العقيدة',
          subtitle: 'بناء الإيمان والفهم الصحيح',
          level: 'مبتدئ',
          lessonsCount: 8,
          progress: 40,
          iconName: 'star',
        ),
        CourseSummary.fallback(
          id: 3,
          title: 'العبادات',
          subtitle: 'الصلاة والطهارة والعبادات اليومية',
          level: 'مبتدئ',
          lessonsCount: 10,
          progress: 30,
          iconName: 'prayer',
        ),
        CourseSummary.fallback(
          id: 4,
          title: 'السيرة النبوية',
          subtitle: 'تعرف على حياة النبي صلى الله عليه وسلم',
          level: 'مبتدئ',
          lessonsCount: 8,
          progress: 25,
          iconName: 'history',
        ),
      ],
    );
  }

  factory CoursesResult.fromResponse(Map<String, dynamic> response) {
    final data = response['data'];

    if (data is! Map<String, dynamic>) {
      return CoursesResult.empty();
    }

    final items = data['data'];

    if (items is! List) {
      return CoursesResult.empty();
    }

    final courses = items
        .whereType<Map<String, dynamic>>()
        .map(CourseSummary.fromJson)
        .toList();

    if (courses.isEmpty) {
      return CoursesResult.empty();
    }

    return CoursesResult(
      courses: courses,
      isSuccess: true,
      message: '',
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

  if (value is num) {
    return value.toInt();
  }

  if (value is String) {
    return int.tryParse(value) ?? fallback;
  }

  return fallback;
}

String _friendlyMessage(
  String message, {
  required String fallback,
}) {
  final text = message.trim();

  if (text.isEmpty) {
    return fallback;
  }

  if (text.contains('No query results') ||
      text.contains('App\\Models') ||
      text.contains('SQLSTATE') ||
      text.contains('Exception')) {
    return fallback;
  }

  return text;
}
