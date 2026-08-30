import 'api_client.dart';
import 'api_endpoints.dart';

class ApiHealthService {
  ApiHealthService({
    ApiClient? apiClient,
  }) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<bool> check() async {
    final response = await _apiClient.get(ApiEndpoints.health);

    return response['success'] == true;
  }
}
