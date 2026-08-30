import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';

class LessonService {
  LessonService({
    ApiClient? apiClient,
    TokenStorage? tokenStorage,
  })  : _apiClient = apiClient ?? ApiClient(),
        _tokenStorage = tokenStorage ?? TokenStorage();

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  Future<LessonDetails> getLesson(int lessonId) async {
    final token = await _tokenStorage.getToken();

    final response = await _apiClient.get(
      '/api/lessons/$lessonId',
      token: token,
    );

    if (response['success'] == true) {
      return LessonDetails.fromResponse(
        response,
        fallbackId: lessonId,
      );
    }

    return LessonDetails.fallback(id: lessonId);
  }

  Future<Map<String, dynamic>> completeLesson(int lessonId) async {
    final token = await _tokenStorage.getToken();

    final response = await _apiClient.post(
      '/api/lessons/$lessonId/complete',
      token: token,
    );

    if (response['success'] == true) {
      return <String, dynamic>{
        ...response,
        'message': response['message']?.toString() ?? 'تم إكمال الدرس بنجاح',
      };
    }

    return <String, dynamic>{
      ...response,
      'success': false,
      'message': _friendlyMessage(
        response['message'],
        fallback: 'تعذر إكمال الدرس الآن',
      ),
    };
  }

  String _friendlyMessage(
    dynamic message, {
    required String fallback,
  }) {
    final text = message?.toString().trim() ?? '';

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
}

class LessonDetails {
  const LessonDetails({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.content,
    required this.duration,
    required this.points,
    required this.isCompleted,
    required this.fileUrl,
    required this.videoUrl,
    required this.audioUrl,
    required this.contents,
    required this.hasQuiz,
    required this.quiz,
  });

  final int id;
  final String title;
  final String subtitle;
  final String content;
  final String duration;
  final int points;
  final bool isCompleted;
  final String fileUrl;
  final String videoUrl;
  final String audioUrl;
  final List<LessonContentBlock> contents;
  final bool hasQuiz;
  final LessonQuiz? quiz;

  bool get hasResources =>
      fileUrl.isNotEmpty || videoUrl.isNotEmpty || audioUrl.isNotEmpty;

  factory LessonDetails.fromResponse(
    Map<String, dynamic> response, {
    required int fallbackId,
  }) {
    final data = response['data'];

    if (data is! Map<String, dynamic>) {
      return LessonDetails.fallback(id: fallbackId);
    }

    final contents = _contentBlocks(data['contents']);
    final quiz = data['quiz'] is Map<String, dynamic>
        ? LessonQuiz.fromJson(data['quiz'] as Map<String, dynamic>)
        : null;

    return LessonDetails(
      id: _asInt(data['id'], fallback: fallbackId),
      title: _asString(
        data['title_ar'] ?? data['title'],
        fallback: 'أركان الإسلام',
      ),
      subtitle: _asString(
        data['summary_ar'] ??
            data['description_ar'] ??
            data['short_description_ar'] ??
            data['course_title'],
        fallback: 'تعرف على الأسس الخمسة التي يقوم عليها الإسلام.',
      ),
      content: _asString(
        data['content_ar'] ?? data['body_ar'] ?? data['content'],
        fallback:
            'يقوم الإسلام على خمسة أركان عظيمة: شهادة أن لا إله إلا الله وأن محمدا رسول الله، وإقام الصلاة، وإيتاء الزكاة، وصوم رمضان، وحج البيت لمن استطاع إليه سبيلا. هذه الأركان هي أساس العمل الظاهر للمسلم، وبها تنتظم علاقته بربه ومجتمعه.',
      ),
      duration: '${_asInt(data['duration_minutes'], fallback: 12)} دقيقة',
      points: _asInt(data['points'], fallback: 15),
      isCompleted: data['is_completed'] == true ||
          data['completed'] == true ||
          data['isCompleted'] == true,
      fileUrl: _asString(data['file_url'], fallback: ''),
      videoUrl: _asString(data['video_url'], fallback: ''),
      audioUrl: _asString(data['audio_url'], fallback: ''),
      contents: contents,
      hasQuiz: _asBool(data['has_quiz'], fallback: quiz != null),
      quiz: quiz,
    );
  }

  factory LessonDetails.fallback({
    int id = 1,
  }) {
    return LessonDetails(
      id: id,
      title: 'أركان الإسلام',
      subtitle: 'تعرف على الأسس الخمسة التي يقوم عليها الإسلام.',
      content:
          'يقوم الإسلام على خمسة أركان عظيمة: شهادة أن لا إله إلا الله وأن محمدا رسول الله، وإقام الصلاة، وإيتاء الزكاة، وصوم رمضان، وحج البيت لمن استطاع إليه سبيلا. هذه الأركان هي أساس العمل الظاهر للمسلم، وبها تنتظم علاقته بربه ومجتمعه.',
      duration: '12 دقيقة',
      points: 15,
      isCompleted: false,
      fileUrl: '',
      videoUrl: '',
      audioUrl: '',
      contents: const [],
      hasQuiz: false,
      quiz: null,
    );
  }

  LessonDetails copyWith({
    bool? isCompleted,
  }) {
    return LessonDetails(
      id: id,
      title: title,
      subtitle: subtitle,
      content: content,
      duration: duration,
      points: points,
      isCompleted: isCompleted ?? this.isCompleted,
      fileUrl: fileUrl,
      videoUrl: videoUrl,
      audioUrl: audioUrl,
      contents: contents,
      hasQuiz: hasQuiz,
      quiz: quiz,
    );
  }
}

class LessonContentBlock {
  const LessonContentBlock({
    required this.id,
    required this.type,
    required this.titleAr,
    required this.contentAr,
    required this.mediaPath,
    required this.meta,
    required this.order,
  });

  final int id;
  final String type;
  final String titleAr;
  final String contentAr;
  final String mediaPath;
  final Map<String, dynamic> meta;
  final int order;

  factory LessonContentBlock.fromJson(Map<String, dynamic> json) {
    return LessonContentBlock(
      id: _asInt(json['id'], fallback: 0),
      type: _asString(json['type'], fallback: 'paragraph'),
      titleAr: _asString(json['title_ar'] ?? json['title'], fallback: ''),
      contentAr: _asString(
        json['content_ar'] ??
            json['content'] ??
            json['body_ar'] ??
            json['body'],
        fallback: '',
      ),
      mediaPath: _asString(
        json['media_path'] ?? json['media_url'] ?? json['file_url'],
        fallback: '',
      ),
      meta: _asMap(json['meta']),
      order: _asInt(json['order'] ?? json['sort_order'], fallback: 0),
    );
  }
}

class LessonQuiz {
  const LessonQuiz({
    required this.id,
    required this.titleAr,
    required this.descriptionAr,
    required this.passingScore,
    required this.questionsCount,
    required this.questions,
  });

  final int id;
  final String titleAr;
  final String descriptionAr;
  final int passingScore;
  final int questionsCount;
  final List<LessonQuizQuestion> questions;

  factory LessonQuiz.fromJson(Map<String, dynamic> json) {
    final questions = _quizQuestions(json['questions']);

    return LessonQuiz(
      id: _asInt(json['id'], fallback: 0),
      titleAr: _asString(json['title_ar'] ?? json['title'], fallback: ''),
      descriptionAr: _asString(
        json['description_ar'] ?? json['description'],
        fallback: '',
      ),
      passingScore: _asInt(json['passing_score'], fallback: 0),
      questionsCount: _asInt(
        json['questions_count'],
        fallback: questions.length,
      ),
      questions: questions,
    );
  }
}

class LessonQuizQuestion {
  const LessonQuizQuestion({
    required this.id,
    required this.questionAr,
    required this.explanationAr,
    required this.order,
    required this.points,
    required this.options,
  });

  final int id;
  final String questionAr;
  final String explanationAr;
  final int order;
  final int points;
  final List<LessonQuizOption> options;

  factory LessonQuizQuestion.fromJson(Map<String, dynamic> json) {
    return LessonQuizQuestion(
      id: _asInt(json['id'], fallback: 0),
      questionAr: _asString(
        json['question_ar'] ?? json['question'] ?? json['title_ar'],
        fallback: '',
      ),
      explanationAr: _asString(
        json['explanation_ar'] ?? json['explanation'],
        fallback: '',
      ),
      order: _asInt(json['order'] ?? json['sort_order'], fallback: 0),
      points: _asInt(json['points'], fallback: 1),
      options: _quizOptions(json['options']),
    );
  }
}

class LessonQuizOption {
  const LessonQuizOption({
    required this.id,
    required this.optionAr,
    required this.order,
  });

  final int id;
  final String optionAr;
  final int order;

  factory LessonQuizOption.fromJson(Map<String, dynamic> json) {
    return LessonQuizOption(
      id: _asInt(json['id'], fallback: 0),
      optionAr: _asString(
        json['option_ar'] ?? json['option'] ?? json['text_ar'] ?? json['text'],
        fallback: '',
      ),
      order: _asInt(json['order'] ?? json['sort_order'], fallback: 0),
    );
  }
}

List<LessonContentBlock> _contentBlocks(dynamic value) {
  if (value is! List) {
    return const [];
  }

  return value
      .whereType<Map<String, dynamic>>()
      .map(LessonContentBlock.fromJson)
      .toList();
}

List<LessonQuizQuestion> _quizQuestions(dynamic value) {
  if (value is! List) {
    return const [];
  }

  return value
      .whereType<Map<String, dynamic>>()
      .map(LessonQuizQuestion.fromJson)
      .toList();
}

List<LessonQuizOption> _quizOptions(dynamic value) {
  if (value is! List) {
    return const [];
  }

  return value
      .whereType<Map<String, dynamic>>()
      .map(LessonQuizOption.fromJson)
      .toList();
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }

  if (value is Map) {
    return value.map(
      (key, item) => MapEntry(key.toString(), item),
    );
  }

  return const {};
}

bool _asBool(dynamic value, {required bool fallback}) {
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

int _asInt(dynamic value, {required int fallback}) {
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

String _asString(dynamic value, {required String fallback}) {
  if (value is String && value.trim().isNotEmpty) {
    return value.trim();
  }

  return fallback;
}
