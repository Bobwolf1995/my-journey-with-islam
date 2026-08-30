import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/storage/token_storage.dart';
import 'notification_item.dart';

class NotificationsService {
  NotificationsService({
    ApiClient? apiClient,
    TokenStorage? tokenStorage,
  })  : _apiClient = apiClient ?? ApiClient(),
        _tokenStorage = tokenStorage ?? TokenStorage();

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  Future<NotificationsResult> getNotifications() async {
    try {
      final token = await _tokenStorage.getToken();

      if (token == null || token.isEmpty) {
        return NotificationsResult.fallback();
      }

      final response = await _apiClient.get(
        ApiEndpoints.notifications,
        token: token,
      );

      if (response['success'] == true) {
        return NotificationsResult.fromResponse(response);
      }

      return NotificationsResult.fallback();
    } catch (_) {
      return NotificationsResult.fallback();
    }
  }

  Future<bool> markAsRead(int notificationId) async {
    if (notificationId <= 0) {
      return false;
    }

    try {
      final token = await _tokenStorage.getToken();

      if (token == null || token.isEmpty) {
        return false;
      }

      final response = await _apiClient.post(
        ApiEndpoints.notificationRead(notificationId),
        token: token,
      );

      return response['success'] == true ||
          response['read'] == true ||
          response['is_read'] == true ||
          response['isRead'] == true ||
          _isReadFromData(response['data']);
    } catch (_) {
      return false;
    }
  }

  bool _isReadFromData(dynamic data) {
    if (data is! Map<String, dynamic>) {
      return false;
    }

    return data['read'] == true ||
        data['is_read'] == true ||
        data['isRead'] == true ||
        data['read_at'] != null;
  }
}
