class CourseDetails {
  const CourseDetails({
    required this.id,
    required this.title,
    required this.description,
    required this.level,
    required this.progress,
    required this.sections,
    required this.standaloneLessons,
  });

  final int id;
  final String title;
  final String description;
  final String level;
  final int progress;
  final List<CourseSection> sections;
  final List<CourseLesson> standaloneLessons;

  int get totalLessons {
    final sectionLessons = sections.fold<int>(
      0,
      (total, section) => total + section.lessons.length,
    );

    return sectionLessons + standaloneLessons.length;
  }

  factory CourseDetails.fallback({
    required int id,
    required String title,
    required String description,
    required String level,
    int progress = 0,
  }) {
    return CourseDetails(
      id: id,
      title: title,
      description: description,
      level: level,
      progress: progress,
      sections: const [
        CourseSection(
          id: 1,
          title: 'مدخل الدورة',
          lessons: [
            CourseLesson(
              id: 1,
              title: 'مقدمة الدورة',
              durationMinutes: 8,
              isPublished: true,
              isFree: true,
              canAccess: true,
              isLocked: false,
              lockReason: '',
            ),
            CourseLesson(
              id: 2,
              title: 'الدرس الأول',
              durationMinutes: 12,
              isPublished: true,
              isFree: true,
              canAccess: true,
              isLocked: false,
              lockReason: '',
            ),
          ],
        ),
        CourseSection(
          id: 2,
          title: 'التطبيق العملي',
          lessons: [
            CourseLesson(
              id: 3,
              title: 'الدرس الثاني',
              durationMinutes: 10,
              isPublished: true,
              isFree: true,
              canAccess: true,
              isLocked: false,
              lockReason: '',
            ),
            CourseLesson(
              id: 4,
              title: 'اختبار قصير',
              durationMinutes: 5,
              isPublished: true,
              isFree: true,
              canAccess: true,
              isLocked: false,
              lockReason: '',
            ),
          ],
        ),
      ],
      standaloneLessons: const [],
    );
  }

  factory CourseDetails.fromResponse(
    Map<String, dynamic> response, {
    required int fallbackId,
    required String fallbackTitle,
    required String fallbackDescription,
    required String fallbackLevel,
    int fallbackProgress = 0,
  }) {
    final data = response['data'];

    if (data is! Map<String, dynamic>) {
      return CourseDetails.fallback(
        id: fallbackId,
        title: fallbackTitle,
        description: fallbackDescription,
        level: fallbackLevel,
        progress: fallbackProgress,
      );
    }

    final sectionsData = data['sections'];
    final lessonsData = data['lessons'];

    return CourseDetails(
      id: _int(data['id'], fallback: fallbackId),
      title: _string(
        data['title_ar'] ?? data['title'],
        fallback: fallbackTitle,
      ),
      description: _string(
        data['description_ar'] ??
            data['short_description_ar'] ??
            data['description'],
        fallback: fallbackDescription,
      ),
      level: _string(data['level'], fallback: fallbackLevel),
      progress: _int(
        data['progress_percentage'] ?? data['progress'] ?? data['percentage'],
        fallback: fallbackProgress,
      ).clamp(0, 100),
      sections: sectionsData is List
          ? sectionsData
              .whereType<Map<String, dynamic>>()
              .map(CourseSection.fromJson)
              .toList()
          : const [],
      standaloneLessons: lessonsData is List
          ? lessonsData
              .whereType<Map<String, dynamic>>()
              .map(CourseLesson.fromJson)
              .toList()
          : const [],
    );
  }
}

class CourseSection {
  const CourseSection({
    required this.id,
    required this.title,
    required this.lessons,
  });

  final int id;
  final String title;
  final List<CourseLesson> lessons;

  factory CourseSection.fromJson(Map<String, dynamic> json) {
    final lessonsData = json['lessons'];

    return CourseSection(
      id: _int(json['id'], fallback: 0),
      title: _string(
        json['title_ar'] ?? json['title'],
        fallback: 'قسم تعليمي',
      ),
      lessons: lessonsData is List
          ? lessonsData
              .whereType<Map<String, dynamic>>()
              .map(CourseLesson.fromJson)
              .toList()
          : const [],
    );
  }
}

class CourseLesson {
  const CourseLesson({
    required this.id,
    required this.title,
    required this.durationMinutes,
    required this.isPublished,
    required this.isFree,
    required this.canAccess,
    required this.isLocked,
    required this.lockReason,
  });

  final int id;
  final String title;
  final int durationMinutes;
  final bool isPublished;
  final bool isFree;
  final bool canAccess;
  final bool isLocked;
  final String lockReason;

  bool get isEffectivelyLocked => isLocked || !canAccess;

  factory CourseLesson.fromJson(Map<String, dynamic> json) {
    final canAccess = _bool(json['can_access'], fallback: true);

    return CourseLesson(
      id: _int(json['id'], fallback: 0),
      title: _string(
        json['title_ar'] ?? json['title'],
        fallback: 'درس تعليمي',
      ),
      durationMinutes: _int(
        json['duration_minutes'] ?? json['duration'],
        fallback: 10,
      ),
      isPublished: json['is_published'] != false,
      isFree: _bool(json['is_free'], fallback: true),
      canAccess: canAccess,
      isLocked: _bool(json['is_locked'], fallback: !canAccess),
      lockReason: _string(
        json['lock_reason'],
        fallback: '',
      ),
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

bool _bool(dynamic value, {required bool fallback}) {
  if (value is bool) {
    return value;
  }

  if (value is num) {
    return value != 0;
  }

  if (value is String) {
    final normalized = value.trim().toLowerCase();

    if (normalized == 'true' || normalized == '1' || normalized == 'yes') {
      return true;
    }

    if (normalized == 'false' || normalized == '0' || normalized == 'no') {
      return false;
    }
  }

  return fallback;
}
