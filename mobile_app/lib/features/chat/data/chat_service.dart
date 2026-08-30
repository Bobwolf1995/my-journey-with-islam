import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/storage/token_storage.dart';
import 'chat_models.dart';

class ChatService {
  ChatService({
    ApiClient? apiClient,
    TokenStorage? tokenStorage,
  })  : _apiClient = apiClient ?? ApiClient(),
        _tokenStorage = tokenStorage ?? TokenStorage();

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  Future<ConversationsResult> getConversations() async {
    try {
      final token = await _tokenStorage.getToken();

      if (token == null || token.isEmpty) {
        return ConversationsResult.fallback();
      }

      final response = await _apiClient.get(
        ApiEndpoints.conversations,
        token: token,
      );

      if (response['success'] == true) {
        return ConversationsResult.fromResponse(response);
      }

      return ConversationsResult.fallback();
    } catch (_) {
      return ConversationsResult.fallback();
    }
  }

  Future<MessagesResult> getMessages(int conversationId) async {
    try {
      final token = await _tokenStorage.getToken();

      if (token == null || token.isEmpty) {
        return MessagesResult.fallback();
      }

      final response = await _apiClient.get(
        ApiEndpoints.conversationMessages(conversationId),
        token: token,
      );

      if (response['success'] == true) {
        return MessagesResult.fromResponse(response);
      }

      return MessagesResult.fallback();
    } catch (_) {
      return MessagesResult.fallback();
    }
  }

  Future<ChatMessage?> sendMessage({
    required int conversationId,
    required String body,
  }) async {
    try {
      final token = await _tokenStorage.getToken();

      if (token == null || token.isEmpty) {
        return null;
      }

      final response = await _apiClient.post(
        ApiEndpoints.conversationMessages(conversationId),
        token: token,
        body: {
          'body': body,
          'message_type': 'text',
        },
      );

      if (response['success'] != true) {
        return null;
      }

      final messageData = _extractMessageData(response['data']);

      if (messageData == null) {
        return null;
      }

      return ChatMessage.fromJson(messageData);
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic>? _extractMessageData(dynamic data) {
    if (data is! Map<String, dynamic>) {
      return null;
    }

    final directMessage = data['message'];
    final directData = data['data'];
    final item = data['item'];

    if (_looksLikeMessage(data)) {
      return data;
    }

    if (directMessage is Map<String, dynamic>) {
      return directMessage;
    }

    if (directData is Map<String, dynamic>) {
      if (_looksLikeMessage(directData)) {
        return directData;
      }

      final nestedMessage = directData['message'];

      if (nestedMessage is Map<String, dynamic>) {
        return nestedMessage;
      }
    }

    if (item is Map<String, dynamic>) {
      return item;
    }

    return null;
  }

  bool _looksLikeMessage(Map<String, dynamic> data) {
    return data.containsKey('body') ||
        data.containsKey('message') ||
        data.containsKey('content') ||
        data.containsKey('text');
  }
}
