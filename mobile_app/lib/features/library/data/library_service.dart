import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/storage/token_storage.dart';
import 'library_item_summary.dart';

class LibraryService {
  LibraryService({
    ApiClient? apiClient,
    TokenStorage? tokenStorage,
  })  : _apiClient = apiClient ?? ApiClient(),
        _tokenStorage = tokenStorage ?? TokenStorage();

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  Future<LibraryResult> getItems({
    String? categorySlug,
  }) async {
    final token = await _tokenStorage.getToken();

    final cleanCategorySlug = categorySlug?.trim() ?? '';
    final path = cleanCategorySlug.isEmpty
        ? '${ApiEndpoints.library}/items'
        : '${ApiEndpoints.library}/items?category_slug=${Uri.encodeQueryComponent(cleanCategorySlug)}';

    final response = await _apiClient.get(
      path,
      token: token,
    );

    if (response['success'] == true) {
      return LibraryResult.fromResponse(response);
    }

    return LibraryResult.fallback();
  }
}
