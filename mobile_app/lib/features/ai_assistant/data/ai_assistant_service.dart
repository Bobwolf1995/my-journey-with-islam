import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/storage/token_storage.dart';
import 'ai_message.dart';

class AiAssistantService {
  AiAssistantService({
    ApiClient? apiClient,
    TokenStorage? tokenStorage,
  })  : _apiClient = apiClient ?? ApiClient(),
        _tokenStorage = tokenStorage ?? TokenStorage();

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  Future<AiMessage> ask(String question) async {
    try {
      final token = await _tokenStorage.getToken();

      if (token == null || token.isEmpty) {
        return AiMessage.fallbackAnswer();
      }

      final response = await _apiClient.post(
        ApiEndpoints.aiAsk,
        token: token,
        body: {
          'question': question,
        },
      );

      if (response['success'] == true) {
        return AiMessage.assistant(response: response);
      }

      return AiMessage.fallbackAnswer();
    } catch (_) {
      return AiMessage.fallbackAnswer();
    }
  }
}
