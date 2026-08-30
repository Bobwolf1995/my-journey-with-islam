import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/storage/token_storage.dart';
import 'badge_item.dart';

class BadgesService {
  BadgesService({
    ApiClient? apiClient,
    TokenStorage? tokenStorage,
  })  : _apiClient = apiClient ?? ApiClient(),
        _tokenStorage = tokenStorage ?? TokenStorage();

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  Future<BadgesResult> getMyBadges() async {
    try {
      final token = await _tokenStorage.getToken();

      if (token == null || token.isEmpty) {
        return BadgesResult.fallback();
      }

      final response = await _apiClient.get(
        ApiEndpoints.badgesMy,
        token: token,
      );

      if (response['success'] == true) {
        return BadgesResult.fromResponse(response);
      }

      return BadgesResult.fallback();
    } catch (_) {
      return BadgesResult.fallback();
    }
  }
}
