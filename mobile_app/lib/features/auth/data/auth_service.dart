import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/storage/token_storage.dart';
import 'current_user.dart';

class AuthService {
  AuthService({
    ApiClient? apiClient,
    TokenStorage? tokenStorage,
  })  : _apiClient = apiClient ?? ApiClient(),
        _tokenStorage = tokenStorage ?? TokenStorage();

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.login,
      body: {
        'email': email,
        'password': password,
      },
    );

    await _saveTokenIfExists(response);

    return response;
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    String accountType = 'user',
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.register,
      body: {
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
        'account_type': accountType,
      },
    );

    await _saveTokenIfExists(response);

    return response;
  }

  Future<Map<String, dynamic>> forgotPassword({
    required String email,
  }) {
    return _apiClient.post(
      ApiEndpoints.forgotPassword,
      body: {
        'email': email,
      },
    );
  }

  Future<CurrentUser> currentUser() async {
    final response = await me();

    if (response['success'] == true) {
      return CurrentUser.fromResponse(response);
    }

    return CurrentUser.fallback();
  }

  Future<Map<String, dynamic>> me() async {
    final token = await _tokenStorage.getToken();

    return _apiClient.get(
      ApiEndpoints.me,
      token: token,
    );
  }

  Future<void> logout() async {
    final token = await _tokenStorage.getToken();

    if (token != null && token.isNotEmpty) {
      await _apiClient.post(
        ApiEndpoints.logout,
        token: token,
      );
    }

    await _tokenStorage.clearToken();
  }

  Future<bool> isLoggedIn() {
    return _tokenStorage.hasToken();
  }

  Future<void> _saveTokenIfExists(Map<String, dynamic> response) async {
    if (response['success'] != true) {
      return;
    }

    final token = _extractToken(response);

    if (token != null && token.isNotEmpty) {
      await _tokenStorage.saveToken(token);
    }
  }

  String? _extractToken(Map<String, dynamic> response) {
    final data = response['data'];

    if (data is Map<String, dynamic>) {
      final token = data['token'] ?? data['access_token'];

      if (token is String) {
        return token;
      }
    }

    final token = response['token'] ?? response['access_token'];

    if (token is String) {
      return token;
    }

    return null;
  }
}
