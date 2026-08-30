import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/storage/token_storage.dart';
import 'community_models.dart';

class CommunityService {
  CommunityService({
    ApiClient? apiClient,
    TokenStorage? tokenStorage,
  })  : _apiClient = apiClient ?? ApiClient(),
        _tokenStorage = tokenStorage ?? TokenStorage();

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  Future<CommunityDashboard> getDashboard() async {
    final groups = await getGroups();
    final posts = await getPosts();

    if (groups.isEmpty && posts.isEmpty) {
      return CommunityDashboard.fallback();
    }

    final fallback = CommunityDashboard.fallback();

    return CommunityDashboard(
      groups: groups.isEmpty ? fallback.groups : groups,
      posts: posts.isEmpty ? fallback.posts : posts,
    );
  }

  Future<Map<String, dynamic>> toggleLike({
    required int postId,
  }) async {
    if (postId <= 0) {
      return <String, dynamic>{
        'success': false,
        'message': 'لا يمكن تنفيذ الإعجاب لهذا المنشور الآن',
      };
    }

    final token = await _tokenStorage.getToken();

    final response = await _apiClient.post(
      '${ApiEndpoints.community}/posts/$postId/like',
      token: token,
      body: {
        'post_id': postId,
      },
    );

    return _normalizeLikeResponse(response);
  }

  Future<Map<String, dynamic>> addComment({
    required int postId,
    required String body,
  }) async {
    if (postId <= 0) {
      return <String, dynamic>{
        'success': false,
        'message': 'لا يمكن إضافة تعليق لهذا المنشور الآن',
      };
    }

    final trimmedBody = body.trim();

    if (trimmedBody.isEmpty) {
      return <String, dynamic>{
        'success': false,
        'message': 'اكتب تعليقًا أولًا',
      };
    }

    final token = await _tokenStorage.getToken();

    return _apiClient.post(
      '${ApiEndpoints.community}/posts/$postId/comments',
      token: token,
      body: {
        'body': trimmedBody,
      },
    );
  }

  Future<List<CommunityGroupSummary>> getGroups() async {
    final token = await _tokenStorage.getToken();

    final response = await _apiClient.get(
      '${ApiEndpoints.community}/groups',
      token: token,
    );

    if (response['success'] != true) {
      return const [];
    }

    final items = _extractItems(
      response['data'],
      primaryKeys: const [
        'groups',
        'items',
        'data',
      ],
    );

    return items
        .whereType<Map<String, dynamic>>()
        .map(CommunityGroupSummary.fromJson)
        .toList();
  }

  Future<List<CommunityPostSummary>> getPosts() async {
    final token = await _tokenStorage.getToken();

    final response = await _apiClient.get(
      '${ApiEndpoints.community}/posts',
      token: token,
    );

    if (response['success'] != true) {
      return const [];
    }

    final items = _extractItems(
      response['data'],
      primaryKeys: const [
        'posts',
        'items',
        'data',
      ],
    );

    return items
        .whereType<Map<String, dynamic>>()
        .map(CommunityPostSummary.fromJson)
        .toList();
  }

  Map<String, dynamic> _normalizeLikeResponse(Map<String, dynamic> response) {
    if (response['success'] == true) {
      return response;
    }

    if (response['success'] == false && response.containsKey('statusCode')) {
      return response;
    }

    final data = response['data'];

    if (_hasLikeState(response)) {
      return <String, dynamic>{
        'success': true,
        'message': response['message']?.toString() ?? 'تم تحديث الإعجاب',
        'data': response,
      };
    }

    if (data is Map<String, dynamic> && _hasLikeState(data)) {
      return <String, dynamic>{
        'success': true,
        'message': response['message']?.toString() ?? 'تم تحديث الإعجاب',
        'data': data,
      };
    }

    return response;
  }

  bool _hasLikeState(Map<String, dynamic> data) {
    return data.containsKey('liked') ||
        data.containsKey('is_liked') ||
        data.containsKey('isLiked') ||
        data.containsKey('likes_count') ||
        data.containsKey('likesCount');
  }

  List<dynamic> _extractItems(
    dynamic data, {
    required List<String> primaryKeys,
  }) {
    if (data is List) {
      return data;
    }

    if (data is Map<String, dynamic>) {
      for (final key in primaryKeys) {
        final value = data[key];

        if (value is List) {
          return value;
        }

        if (value is Map<String, dynamic>) {
          final nested = _extractItems(
            value,
            primaryKeys: primaryKeys,
          );

          if (nested.isNotEmpty) {
            return nested;
          }
        }
      }
    }

    return <dynamic>[];
  }
}
