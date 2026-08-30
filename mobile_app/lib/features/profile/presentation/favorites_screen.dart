import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/storage/token_storage.dart';
import '../../../shared/theme/app_colors.dart';
import '../../courses/presentation/lesson_details_page.dart';
import '../../library/presentation/library_page.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final FavoritesService _favoritesService = FavoritesService();

  late Future<FavoritesResult> _favoritesFuture;

  FavoritesResult? _favoritesResult;
  final Set<String> _deletingKeys = <String>{};

  @override
  void initState() {
    super.initState();
    _favoritesFuture = _loadFavorites();
  }

  Future<FavoritesResult> _loadFavorites() async {
    final result = await _favoritesService.getFavorites();
    _favoritesResult = result;
    return result;
  }

  Future<void> _refresh() async {
    setState(() {
      _favoritesFuture = _loadFavorites();
    });

    await _favoritesFuture;
  }

  void _openFavorite(FavoriteItem favorite) {
    if (favorite.isLesson) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => LessonDetailsPage(lessonId: favorite.itemId),
        ),
      );
      return;
    }

    if (favorite.fileUrl.isNotEmpty) {
      _openFavoriteFile(favorite.fileUrl);
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const LibraryPage(),
      ),
    );
  }

  Future<void> _openFavoriteFile(String url) async {
    final uri = Uri.tryParse(url.trim());

    if (uri == null) {
      _showMessage('تعذر فتح الملف الآن');
      return;
    }

    try {
      final opened = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!opened) {
        _showMessage('تعذر فتح الملف الآن');
      }
    } catch (_) {
      _showMessage('تعذر فتح الملف الآن');
    }
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          textAlign: TextAlign.right,
        ),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _removeFavorite(FavoriteItem favorite) async {
    if (_deletingKeys.contains(favorite.key)) {
      return;
    }

    setState(() {
      _deletingKeys.add(favorite.key);
    });

    final response = await _favoritesService.removeFavorite(favorite);

    if (!mounted) {
      return;
    }

    final success = response['success'] == true;

    setState(() {
      _deletingKeys.remove(favorite.key);

      if (success && _favoritesResult != null) {
        _favoritesResult = _favoritesResult!.remove(favorite);
        _favoritesFuture = Future.value(_favoritesResult);
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'تم حذف العنصر من المفضلة'
              : response['message']?.toString() ?? 'تعذر حذف العنصر الآن',
          textAlign: TextAlign.right,
        ),
        backgroundColor: success ? AppColors.primary : AppColors.danger,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: FutureBuilder<FavoritesResult>(
            future: _favoritesFuture,
            builder: (context, snapshot) {
              final isLoading =
                  snapshot.connectionState == ConnectionState.waiting;
              final result = _favoritesResult ?? snapshot.data;

              return RefreshIndicator(
                color: AppColors.primary,
                backgroundColor: AppColors.surface,
                onRefresh: _refresh,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _FavoritesHeader(),
                      const SizedBox(height: 18),
                      const _FavoritesIntro(),
                      const SizedBox(height: 18),
                      if (isLoading && result == null)
                        const _LoadingCard()
                      else if (result == null)
                        _FallbackMessageCard(
                          message: 'تعذر تحميل المفضلة الآن',
                          onRetry: _refresh,
                        )
                      else ...[
                        if (result.isFallback) ...[
                          _FallbackMessageCard(
                            message: result.message,
                            onRetry: _refresh,
                          ),
                          const SizedBox(height: 14),
                        ],
                        if (result.favorites.isEmpty)
                          const _EmptyFavoritesCard()
                        else
                          _FavoritesList(
                            favorites: result.favorites,
                            deletingKeys: _deletingKeys,
                            onFavoriteTap: _openFavorite,
                            onFavoriteRemove: _removeFavorite,
                          ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class FavoritesService {
  FavoritesService({
    ApiClient? apiClient,
    TokenStorage? tokenStorage,
  })  : _apiClient = apiClient ?? ApiClient(),
        _tokenStorage = tokenStorage ?? TokenStorage();

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  Future<FavoritesResult> getFavorites() async {
    try {
      final token = await _tokenStorage.getToken();

      final response = await _apiClient.get(
        ApiEndpoints.favorites,
        token: token,
      );

      if (response['success'] == true) {
        return FavoritesResult.fromResponse(response);
      }

      return FavoritesResult.fallback(
        message: response['message']?.toString() ?? 'تعذر تحميل المفضلة الآن',
      );
    } catch (_) {
      return FavoritesResult.fallback();
    }
  }

  Future<Map<String, dynamic>> removeFavorite(FavoriteItem favorite) async {
    try {
      final token = await _tokenStorage.getToken();

      return _apiClient.delete(
        ApiEndpoints.favorites,
        token: token,
        body: {
          'type': favorite.apiType,
          'id': favorite.itemId,
        },
      );
    } catch (_) {
      return {
        'success': false,
        'message': 'تعذر حذف العنصر الآن',
      };
    }
  }
}

class FavoritesResult {
  const FavoritesResult({
    required this.favorites,
    required this.isFallback,
    required this.message,
  });

  final List<FavoriteItem> favorites;
  final bool isFallback;
  final String message;

  FavoritesResult remove(FavoriteItem favorite) {
    return FavoritesResult(
      favorites: favorites
          .where((item) => item.key != favorite.key)
          .toList(growable: false),
      isFallback: isFallback,
      message: message,
    );
  }

  factory FavoritesResult.fromResponse(Map<String, dynamic> response) {
    final items = _extractItems(response);

    final favorites = items
        .whereType<Map<String, dynamic>>()
        .map(FavoriteItem.fromJson)
        .where((favorite) => favorite.title.trim().isNotEmpty)
        .toList();

    return FavoritesResult(
      favorites: favorites,
      isFallback: false,
      message: '',
    );
  }

  factory FavoritesResult.fallback({
    String message = 'نعرض مفضلات تجريبية مؤقتًا لحين توفر الاتصال.',
  }) {
    return FavoritesResult(
      isFallback: true,
      message: message,
      favorites: [
        FavoriteItem.fallback(
          id: 1,
          itemId: 1,
          type: FavoriteType.lesson,
          title: 'أركان الإسلام',
          subtitle: 'درس محفوظ من مسار الأساسيات',
          tag: 'درس',
        ),
        FavoriteItem.fallback(
          id: 2,
          itemId: 2,
          type: FavoriteType.lesson,
          title: 'معنى التوحيد',
          subtitle: 'محتوى مبسط لبناء الفهم الصحيح',
          tag: 'تعلم',
        ),
        FavoriteItem.fallback(
          id: 3,
          itemId: 1,
          type: FavoriteType.library,
          title: 'دليل المسلم الجديد',
          subtitle: 'كتاب مختصر يساعدك في بداية الرحلة',
          tag: 'كتاب',
        ),
      ],
    );
  }

  static List<dynamic> _extractItems(Map<String, dynamic> response) {
    final data = response['data'];

    if (data is List) {
      return data;
    }

    if (data is Map<String, dynamic>) {
      final paginatedItems = data['data'];

      if (paginatedItems is List) {
        return paginatedItems;
      }

      final favorites = data['favorites'];

      if (favorites is List) {
        return favorites;
      }

      final items = data['items'];

      if (items is List) {
        return items;
      }
    }

    return const [];
  }
}

enum FavoriteType {
  lesson,
  library,
}

class FavoriteItem {
  const FavoriteItem({
    required this.id,
    required this.itemId,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.tag,
    required this.coverImageUrl,
    required this.fileUrl,
  });

  final int id;
  final int itemId;
  final FavoriteType type;
  final String title;
  final String subtitle;
  final String tag;
  final String coverImageUrl;
  final String fileUrl;

  bool get isLesson => type == FavoriteType.lesson;

  String get apiType => isLesson ? 'lesson' : 'library_item';

  String get key => '$apiType-$itemId';

  IconData get icon {
    if (isLesson) {
      return Icons.menu_book_rounded;
    }

    if (tag.toLowerCase().contains('pdf')) {
      return Icons.picture_as_pdf_rounded;
    }

    return Icons.local_library_rounded;
  }

  Color get color {
    if (isLesson) {
      return AppColors.primary;
    }

    if (tag.toLowerCase().contains('pdf')) {
      return const Color(0xFF2C7DA0);
    }

    return AppColors.secondary;
  }

  factory FavoriteItem.fallback({
    required int id,
    required int itemId,
    required FavoriteType type,
    required String title,
    required String subtitle,
    required String tag,
    String coverImageUrl = '',
    String fileUrl = '',
  }) {
    return FavoriteItem(
      id: id,
      itemId: itemId,
      type: type,
      title: title,
      subtitle: subtitle,
      tag: tag,
      coverImageUrl: coverImageUrl,
      fileUrl: fileUrl,
    );
  }

  factory FavoriteItem.fromJson(Map<String, dynamic> json) {
    final item = _extractFavoriteObject(json);
    final type = _resolveType(json, item);

    return FavoriteItem(
      id: _asInt(json['id'], fallback: _asInt(item['id'], fallback: 0)),
      itemId: _asInt(
        json['favoritable_id'] ??
            json['favoriteable_id'] ??
            json['item_id'] ??
            json['lesson_id'] ??
            json['library_item_id'] ??
            item['id'],
        fallback: 1,
      ),
      type: type,
      title: _asString(
        item['title_ar'] ??
            item['name_ar'] ??
            item['title'] ??
            item['name'] ??
            json['title_ar'] ??
            json['name_ar'] ??
            json['title'] ??
            json['name'],
        fallback: type == FavoriteType.lesson ? 'درس محفوظ' : 'عنصر محفوظ',
      ),
      subtitle: _asString(
        item['summary_ar'] ??
            item['description_ar'] ??
            item['short_description_ar'] ??
            item['summary'] ??
            item['description'] ??
            json['summary_ar'] ??
            json['description_ar'] ??
            json['description'] ??
            json['subtitle'],
        fallback: type == FavoriteType.lesson
            ? 'درس محفوظ في المفضلة'
            : 'عنصر محفوظ من المكتبة',
      ),
      tag: _resolveTag(json, item, type),
      coverImageUrl: _asString(
        item['cover_image_url'] ??
            item['cover_image'] ??
            item['thumbnail'] ??
            json['cover_image_url'] ??
            json['cover_image'] ??
            json['thumbnail'],
        fallback: '',
      ),
      fileUrl: _asString(
        item['file_url'] ??
            item['file_path'] ??
            json['file_url'] ??
            json['file_path'],
        fallback: '',
      ),
    );
  }

  static Map<String, dynamic> _extractFavoriteObject(
    Map<String, dynamic> json,
  ) {
    final possibleKeys = [
      'favoritable',
      'favoriteable',
      'item',
      'lesson',
      'library_item',
      'libraryItem',
      'book',
      'resource',
    ];

    for (final key in possibleKeys) {
      final value = json[key];

      if (value is Map<String, dynamic>) {
        return value;
      }
    }

    return json;
  }

  static FavoriteType _resolveType(
    Map<String, dynamic> json,
    Map<String, dynamic> item,
  ) {
    final rawType = _asString(
      json['favoritable_type'] ??
          json['favoriteable_type'] ??
          json['type'] ??
          json['item_type'] ??
          item['type'] ??
          item['content_type'],
      fallback: '',
    ).toLowerCase();

    if (rawType.contains('lesson') || rawType.contains('درس')) {
      return FavoriteType.lesson;
    }

    if (json['lesson_id'] != null || item['duration_minutes'] != null) {
      return FavoriteType.lesson;
    }

    return FavoriteType.library;
  }

  static String _resolveTag(
    Map<String, dynamic> json,
    Map<String, dynamic> item,
    FavoriteType type,
  ) {
    final rawTag = _asString(
      item['tag'] ??
          item['type'] ??
          item['content_type'] ??
          json['tag'] ??
          json['type'] ??
          json['item_type'],
      fallback: '',
    );

    if (rawTag.trim().isNotEmpty) {
      if (rawTag.toLowerCase().contains('pdf')) {
        return 'PDF';
      }

      if (rawTag.toLowerCase().contains('book')) {
        return 'كتاب';
      }

      if (rawTag.toLowerCase().contains('lesson')) {
        return 'درس';
      }

      if (rawTag.toLowerCase().contains('library')) {
        return 'مكتبة';
      }

      return rawTag;
    }

    return type == FavoriteType.lesson ? 'درس' : 'مكتبة';
  }
}

class _FavoritesList extends StatelessWidget {
  const _FavoritesList({
    required this.favorites,
    required this.deletingKeys,
    required this.onFavoriteTap,
    required this.onFavoriteRemove,
  });

  final List<FavoriteItem> favorites;
  final Set<String> deletingKeys;
  final ValueChanged<FavoriteItem> onFavoriteTap;
  final ValueChanged<FavoriteItem> onFavoriteRemove;

  @override
  Widget build(BuildContext context) {
    final lessonFavorites =
        favorites.where((favorite) => favorite.isLesson).toList();
    final libraryFavorites =
        favorites.where((favorite) => !favorite.isLesson).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (lessonFavorites.isNotEmpty) ...[
          const _SectionTitle(title: 'الدروس المحفوظة'),
          const SizedBox(height: 12),
          for (var index = 0; index < lessonFavorites.length; index++) ...[
            _FavoriteCard(
              favorite: lessonFavorites[index],
              isDeleting: deletingKeys.contains(lessonFavorites[index].key),
              onTap: () => onFavoriteTap(lessonFavorites[index]),
              onRemove: () => onFavoriteRemove(lessonFavorites[index]),
            ),
            if (index != lessonFavorites.length - 1) const SizedBox(height: 12),
          ],
        ],
        if (lessonFavorites.isNotEmpty && libraryFavorites.isNotEmpty)
          const SizedBox(height: 18),
        if (libraryFavorites.isNotEmpty) ...[
          const _SectionTitle(title: 'من المكتبة'),
          const SizedBox(height: 12),
          for (var index = 0; index < libraryFavorites.length; index++) ...[
            _FavoriteCard(
              favorite: libraryFavorites[index],
              isDeleting: deletingKeys.contains(libraryFavorites[index].key),
              onTap: () => onFavoriteTap(libraryFavorites[index]),
              onRemove: () => onFavoriteRemove(libraryFavorites[index]),
            ),
            if (index != libraryFavorites.length - 1)
              const SizedBox(height: 12),
          ],
        ],
      ],
    );
  }
}

class _FavoritesHeader extends StatelessWidget {
  const _FavoritesHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _CircleButton(
          icon: Icons.arrow_back_ios_new_rounded,
          onTap: () {
            Navigator.of(context).pop();
          },
        ),
        const Spacer(),
        const Column(
          children: [
            Text(
              'مفضلاتي',
              style: TextStyle(
                color: AppColors.text,
                fontSize: 23,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: 3),
            Text(
              'الدروس والعناصر المحفوظة',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const Spacer(),
        const SizedBox(width: 44),
      ],
    );
  }
}

class _FavoritesIntro extends StatelessWidget {
  const _FavoritesIntro();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderSoft),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 18,
            offset: Offset(0, 9),
          ),
        ],
      ),
      child: const Row(
        children: [
          _IntroIcon(),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'كل ما حفظته في مكان واحد',
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'ارجع بسرعة إلى الدروس والكتب والملفات التي تهمك.',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                    height: 1.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IntroIcon extends StatelessWidget {
  const _IntroIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Icon(
        Icons.favorite_rounded,
        color: AppColors.primary,
        size: 30,
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      textAlign: TextAlign.right,
      style: const TextStyle(
        color: AppColors.text,
        fontSize: 18,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _FavoriteCard extends StatelessWidget {
  const _FavoriteCard({
    required this.favorite,
    required this.isDeleting,
    required this.onTap,
    required this.onRemove,
  });

  final FavoriteItem favorite;
  final bool isDeleting;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: isDeleting ? null : onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.borderSoft),
            boxShadow: const [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 16,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              _RemoveFavoriteButton(
                isDeleting: isDeleting,
                onTap: onRemove,
              ),
              const SizedBox(width: 8),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.surfaceSoft,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderSoft),
                ),
                child: const Icon(
                  Icons.chevron_left_rounded,
                  color: AppColors.textMuted,
                  size: 22,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      favorite.title,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      favorite.subtitle,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                        height: 1.45,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: favorite.color.withValues(alpha: 0.11),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: favorite.color.withValues(alpha: 0.12),
                          ),
                        ),
                        child: Text(
                          favorite.tag,
                          style: TextStyle(
                            color: favorite.color,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              _FavoriteVisual(favorite: favorite),
            ],
          ),
        ),
      ),
    );
  }
}

class _FavoriteVisual extends StatelessWidget {
  const _FavoriteVisual({
    required this.favorite,
  });

  final FavoriteItem favorite;

  @override
  Widget build(BuildContext context) {
    if (favorite.coverImageUrl.isEmpty) {
      return _FavoriteIcon(favorite: favorite);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        width: 58,
        height: 58,
        child: Image.network(
          favorite.coverImageUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _FavoriteIcon(favorite: favorite);
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) {
              return child;
            }

            return Container(
              decoration: BoxDecoration(
                color: favorite.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _FavoriteIcon extends StatelessWidget {
  const _FavoriteIcon({
    required this.favorite,
  });

  final FavoriteItem favorite;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        color: favorite.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Icon(
        favorite.icon,
        color: favorite.color,
        size: 28,
      ),
    );
  }
}

class _RemoveFavoriteButton extends StatelessWidget {
  const _RemoveFavoriteButton({
    required this.isDeleting,
    required this.onTap,
  });

  final bool isDeleting;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isDeleting ? null : onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.danger.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.danger.withValues(alpha: 0.12),
          ),
        ),
        child: isDeleting
            ? const Padding(
                padding: EdgeInsets.all(9),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.danger,
                ),
              )
            : const Icon(
                Icons.favorite_rounded,
                color: AppColors.danger,
                size: 21,
              ),
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 42),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderSoft),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: const Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
          strokeWidth: 2.6,
        ),
      ),
    );
  }
}

class _EmptyFavoritesCard extends StatelessWidget {
  const _EmptyFavoritesCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderSoft),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: const Column(
        children: [
          Icon(
            Icons.favorite_border_rounded,
            color: AppColors.textMuted,
            size: 42,
          ),
          SizedBox(height: 12),
          Text(
            'لا توجد مفضلات بعد',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.text,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'عندما تحفظ درسًا أو عنصرًا من المكتبة سيظهر هنا.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 13,
              height: 1.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _FallbackMessageCard extends StatelessWidget {
  const _FallbackMessageCard({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.warning.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(
              Icons.refresh_rounded,
              size: 18,
            ),
            label: const Text('إعادة المحاولة'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              textStyle: const TextStyle(
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _friendlyMessage(message),
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 12,
                height: 1.45,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(17),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: AppColors.borderSoft),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 16,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: AppColors.text,
          size: 20,
        ),
      ),
    );
  }
}

String _friendlyMessage(String message) {
  final trimmed = message.trim();

  if (trimmed.isEmpty ||
      trimmed.contains('SQLSTATE') ||
      trimmed.contains('Exception') ||
      trimmed.contains('App\\Models') ||
      trimmed.contains('No query results')) {
    return 'تعذر تحميل المفضلة الآن، يتم عرض بيانات مؤقتة.';
  }

  return trimmed;
}

String _asString(dynamic value, {required String fallback}) {
  if (value is String && value.trim().isNotEmpty) {
    return value.trim();
  }

  return fallback;
}

int _asInt(dynamic value, {required int fallback}) {
  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  if (value is String) {
    return int.tryParse(value) ?? fallback;
  }

  return fallback;
}
