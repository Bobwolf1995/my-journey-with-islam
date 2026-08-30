import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/storage/token_storage.dart';

class QuizService {
  QuizService({
    ApiClient? apiClient,
    TokenStorage? tokenStorage,
  })  : _apiClient = apiClient ?? ApiClient(),
        _tokenStorage = tokenStorage ?? TokenStorage();

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  Future<QuizSubmitResult> submitQuiz({
    required int quizId,
    required List<QuizAnswerPayload> answers,
  }) async {
    try {
      final token = await _tokenStorage.getToken();

      final response = await _apiClient.post(
        ApiEndpoints.quizSubmit(quizId),
        token: token,
        body: {
          'answers': answers.map((answer) => answer.toJson()).toList(),
        },
      );

      if (response['success'] == true) {
        return QuizSubmitResult.fromResponse(response);
      }

      return QuizSubmitResult.failure(
        message: response['message']?.toString() ?? 'تعذر إرسال الاختبار الآن',
      );
    } catch (_) {
      return const QuizSubmitResult(
        success: false,
        message: 'تعذر إرسال الاختبار الآن',
        score: 0,
        passed: false,
        correctAnswers: 0,
        totalQuestions: 0,
      );
    }
  }
}

class QuizAnswerPayload {
  const QuizAnswerPayload({
    required this.questionId,
    required this.optionId,
  });

  final int questionId;
  final int optionId;

  Map<String, dynamic> toJson() {
    return {
      'question_id': questionId,
      'option_id': optionId,
    };
  }
}

class QuizSubmitResult {
  const QuizSubmitResult({
    required this.success,
    required this.message,
    required this.score,
    required this.passed,
    required this.correctAnswers,
    required this.totalQuestions,
  });

  final bool success;
  final String message;
  final int score;
  final bool passed;
  final int correctAnswers;
  final int totalQuestions;

  factory QuizSubmitResult.fromResponse(Map<String, dynamic> response) {
    final data = response['data'];

    if (data is! Map<String, dynamic>) {
      return QuizSubmitResult(
        success: true,
        message: response['message']?.toString() ?? 'تم إرسال الاختبار بنجاح',
        score: 0,
        passed: false,
        correctAnswers: 0,
        totalQuestions: 0,
      );
    }

    return QuizSubmitResult(
      success: true,
      message: response['message']?.toString() ?? 'تم إرسال الاختبار بنجاح',
      score: _asInt(data['score'] ?? data['percentage'], fallback: 0),
      passed: _asBool(data['passed'] ?? data['is_passed'], fallback: false),
      correctAnswers: _asInt(
        data['correct_answers'] ?? data['correct_count'],
        fallback: 0,
      ),
      totalQuestions: _asInt(
        data['total_questions'] ?? data['questions_count'],
        fallback: 0,
      ),
    );
  }

  factory QuizSubmitResult.failure({
    required String message,
  }) {
    return QuizSubmitResult(
      success: false,
      message: message,
      score: 0,
      passed: false,
      correctAnswers: 0,
      totalQuestions: 0,
    );
  }
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
