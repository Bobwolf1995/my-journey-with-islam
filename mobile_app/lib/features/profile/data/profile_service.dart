import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/storage/token_storage.dart';
import '../../auth/data/current_user.dart';

class ProfileService {
  ProfileService({
    ApiClient? apiClient,
    TokenStorage? tokenStorage,
  })  : _apiClient = apiClient ?? ApiClient(),
        _tokenStorage = tokenStorage ?? TokenStorage();

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  Future<CurrentUser> getProfile() async {
    try {
      final token = await _tokenStorage.getToken();

      final response = await _apiClient.get(
        ApiEndpoints.profile,
        token: token,
      );

      if (response['success'] == true) {
        return CurrentUser.fromResponse(response);
      }

      return CurrentUser.fallback();
    } catch (_) {
      return CurrentUser.fallback();
    }
  }

  Future<Map<String, dynamic>> updateProfile({
    required String name,
    required String phone,
    required String country,
    required String city,
    required String language,
  }) async {
    final token = await _tokenStorage.getToken();

    return _apiClient.put(
      ApiEndpoints.profile,
      token: token,
      body: {
        'name': name,
        'phone': phone,
        'country': country,
        'city': city,
        'language': language,
      },
    );
  }
}
