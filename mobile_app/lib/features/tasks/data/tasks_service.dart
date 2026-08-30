import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/storage/token_storage.dart';
import 'task_item.dart';

class TasksService {
  TasksService({
    ApiClient? apiClient,
    TokenStorage? tokenStorage,
  })  : _apiClient = apiClient ?? ApiClient(),
        _tokenStorage = tokenStorage ?? TokenStorage();

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  Future<TasksResult> getTasks() async {
    try {
      final token = await _tokenStorage.getToken();

      final response = await _apiClient.get(
        ApiEndpoints.tasks,
        token: token,
      );

      if (response['success'] == true) {
        return TasksResult.fromResponse(response);
      }

      return TasksResult.fallback();
    } catch (_) {
      return TasksResult.fallback();
    }
  }

  Future<Map<String, dynamic>> completeTask({
    required int taskId,
  }) async {
    if (taskId <= 0) {
      return <String, dynamic>{
        'success': false,
        'message': 'لا يمكن إكمال هذه المهمة الآن',
      };
    }

    try {
      final token = await _tokenStorage.getToken();

      final response = await _apiClient.post(
        '${ApiEndpoints.tasks}/$taskId/complete',
        token: token,
      );

      if (response['success'] == true ||
          response['completed'] == true ||
          response['is_completed'] == true ||
          _isCompletedFromData(response['data'])) {
        return <String, dynamic>{
          ...response,
          'success': true,
        };
      }

      return response;
    } catch (_) {
      return <String, dynamic>{
        'success': false,
        'message': 'تعذر إكمال المهمة الآن',
      };
    }
  }

  bool _isCompletedFromData(dynamic data) {
    if (data is! Map<String, dynamic>) {
      return false;
    }

    return data['completed'] == true ||
        data['is_completed'] == true ||
        data['isCompleted'] == true ||
        data['status'] == 'completed';
  }
}
