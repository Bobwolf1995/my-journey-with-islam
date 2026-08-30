import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/storage/token_storage.dart';
import 'course_details.dart';
import 'course_summary.dart';

class CoursesService {
  CoursesService({
    ApiClient? apiClient,
    TokenStorage? tokenStorage,
  })  : _apiClient = apiClient ?? ApiClient(),
        _tokenStorage = tokenStorage ?? TokenStorage();

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  Future<CoursesResult> getCourses() async {
    final token = await _tokenStorage.getToken();

    final response = await _apiClient.get(
      ApiEndpoints.courses,
      token: token,
    );

    if (response['success'] == true) {
      return CoursesResult.fromResponse(response);
    }

    return CoursesResult.failure(
      message: response['message']?.toString() ?? 'تعذر تحميل الدورات الآن',
    );
  }

  Future<Map<String, dynamic>> enroll({
    required int courseId,
  }) async {
    final token = await _tokenStorage.getToken();

    return _apiClient.post(
      '${ApiEndpoints.courses}/$courseId/enroll',
      token: token,
    );
  }

  Future<CourseDetails> getCourseDetails({
    required int courseId,
    required String fallbackTitle,
    required String fallbackDescription,
    required String fallbackLevel,
    int fallbackProgress = 0,
  }) async {
    final token = await _tokenStorage.getToken();

    final response = await _apiClient.get(
      '${ApiEndpoints.courses}/$courseId',
      token: token,
    );

    if (response['success'] == true) {
      return CourseDetails.fromResponse(
        response,
        fallbackId: courseId,
        fallbackTitle: fallbackTitle,
        fallbackDescription: fallbackDescription,
        fallbackLevel: fallbackLevel,
        fallbackProgress: fallbackProgress,
      );
    }

    return CourseDetails.fallback(
      id: courseId,
      title: fallbackTitle,
      description: fallbackDescription,
      level: fallbackLevel,
      progress: fallbackProgress,
    );
  }
}
