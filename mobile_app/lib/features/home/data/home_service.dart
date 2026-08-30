import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/storage/token_storage.dart';
import 'home_dashboard.dart';

class HomeService {
  HomeService({
    ApiClient? apiClient,
    TokenStorage? tokenStorage,
  })  : _apiClient = apiClient ?? ApiClient(),
        _tokenStorage = tokenStorage ?? TokenStorage();

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  Future<HomeDashboard> getDashboard() async {
    final token = await _tokenStorage.getToken();

    final response = await _apiClient.get(
      ApiEndpoints.home,
      token: token,
    );

    if (response['success'] == true) {
      return HomeDashboard.fromResponse(response);
    }

    return HomeDashboard.fallback();
  }
}
