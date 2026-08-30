import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/storage/token_storage.dart';
import '../../shared/theme/app_colors.dart';
import 'cart_screen.dart';
import 'data/library_item_summary.dart';

class LibraryItemDetailsScreen extends StatefulWidget {
  const LibraryItemDetailsScreen({
    super.key,
    required this.item,
  });

  final LibraryItemSummary item;

  @override
  State<LibraryItemDetailsScreen> createState() =>
      _LibraryItemDetailsScreenState();
}

class _LibraryItemDetailsScreenState extends State<LibraryItemDetailsScreen> {
  final LibraryItemFavoriteService _favoriteService =
      LibraryItemFavoriteService();

  bool _isFavorite = false;
  bool _isFavoriteLoading = false;

  LibraryItemSummary get item => widget.item;

  IconData get _icon {
    final type = item.type.toLowerCase();

    if (type.contains('audio')) {
      return Icons.headphones_rounded;
    }

    if (type.contains('pdf')) {
      return Icons.picture_as_pdf_rounded;
    }

    if (type.contains('gift') || type.contains('product')) {
      return Icons.card_giftcard_rounded;
    }

    if (type.contains('video') || type.contains('course')) {
      return Icons.video_library_rounded;
    }

    return Icons.menu_book_rounded;
  }

  String get _typeLabel {
    final type = item.type.toLowerCase();

    if (type.contains('audio')) {
      return 'مادة صوتية';
    }

    if (type.contains('pdf')) {
      return 'ملف PDF';
    }

    if (type.contains('gift') || type.contains('product')) {
      return 'منتج دعوي';
    }

    if (type.contains('video') || type.contains('course')) {
      return 'دورة مرئية';
    }

    return 'كتاب';
  }

  @override
  void initState() {
    super.initState();
    _loadFavoriteState();
  }

  Future<void> _loadFavoriteState() async {
    final isFavorite = await _favoriteService.isLibraryItemFavorite(item.id);

    if (!mounted) {
      return;
    }

    setState(() {
      _isFavorite = isFavorite;
    });
  }

  Future<void> _toggleFavorite() async {
    if (_isFavoriteLoading) {
      return;
    }

    setState(() {
      _isFavoriteLoading = true;
    });

    final response = await _favoriteService.toggleLibraryItem(item.id);

    if (!mounted) {
      return;
    }

    final success = response['success'] == true;
    final nextValue = _extractFavoriteState(
      response,
      fallback: !_isFavorite,
    );

    setState(() {
      _isFavoriteLoading = false;

      if (success) {
        _isFavorite = nextValue;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? (_isFavorite
                  ? 'تمت إضافة العنصر إلى المفضلة'
                  : 'تم حذف العنصر من المفضلة')
              : response['message']?.toString() ?? 'تعذر تحديث المفضلة الآن',
          textAlign: TextAlign.right,
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: success ? AppColors.primary : AppColors.danger,
      ),
    );
  }

  bool _extractFavoriteState(
    Map<String, dynamic> response, {
    required bool fallback,
  }) {
    final data = response['data'];

    if (data is Map<String, dynamic>) {
      final value =
          data['is_favorite'] ?? data['favorite'] ?? data['favorited'];

      if (value is bool) {
        return value;
      }

      final liked = data['liked'];

      if (liked is bool) {
        return liked;
      }
    }

    final value = response['is_favorite'] ??
        response['favorite'] ??
        response['favorited'];

    if (value is bool) {
      return value;
    }

    return fallback;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _LibraryItemHeader(
                isFavorite: _isFavorite,
                isFavoriteLoading: _isFavoriteLoading,
                onFavoriteTap: _toggleFavorite,
              ),
              const SizedBox(height: 18),
              _ItemHeroCard(
                item: item,
                icon: _icon,
                typeLabel: _typeLabel,
              ),
              const SizedBox(height: 14),
              _ItemInfoCard(
                item: item,
                typeLabel: _typeLabel,
              ),
              const SizedBox(height: 14),
              _ItemDescriptionCard(item: item),
              const SizedBox(height: 14),
              _ItemActionCard(item: item),
            ],
          ),
        ),
      ),
    );
  }
}

class _LibraryItemHeader extends StatelessWidget {
  const _LibraryItemHeader({
    required this.isFavorite,
    required this.isFavoriteLoading,
    required this.onFavoriteTap,
  });

  final bool isFavorite;
  final bool isFavoriteLoading;
  final VoidCallback onFavoriteTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _CircleButton(
          icon: Icons.arrow_back_ios_new_rounded,
          onTap: () => Navigator.of(context).pop(),
        ),
        const Spacer(),
        const Column(
          children: [
            Text(
              'تفاصيل العنصر',
              style: TextStyle(
                color: AppColors.text,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: 3),
            Text(
              'معلومات المكتبة',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const Spacer(),
        _FavoriteButton(
          isFavorite: isFavorite,
          isLoading: isFavoriteLoading,
          onTap: onFavoriteTap,
        ),
      ],
    );
  }
}

class _FavoriteButton extends StatelessWidget {
  const _FavoriteButton({
    required this.isFavorite,
    required this.isLoading,
    required this.onTap,
  });

  final bool isFavorite;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(17),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isFavorite
              ? AppColors.danger.withValues(alpha: 0.10)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(
            color: isFavorite
                ? AppColors.danger.withValues(alpha: 0.22)
                : AppColors.borderSoft,
          ),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 16,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: isLoading
            ? const Padding(
                padding: EdgeInsets.all(11),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              )
            : Icon(
                isFavorite
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                color: isFavorite ? AppColors.danger : AppColors.text,
                size: 21,
              ),
      ),
    );
  }
}

class _ItemHeroCard extends StatelessWidget {
  const _ItemHeroCard({
    required this.item,
    required this.icon,
    required this.typeLabel,
  });

  final LibraryItemSummary item;
  final IconData icon;
  final String typeLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            AppColors.primary,
            AppColors.primaryDark,
          ],
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.18),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _HeroCover(
            imageUrl: item.coverImageUrl,
            icon: icon,
          ),
          const SizedBox(height: 18),
          Text(
            item.title,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              height: 1.35,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          _HeroTypeBadge(typeLabel: typeLabel),
        ],
      ),
    );
  }
}

class _HeroCover extends StatelessWidget {
  const _HeroCover({
    required this.imageUrl,
    required this.icon,
  });

  final String imageUrl;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 88,
      height: 88,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.10),
        ),
      ),
      child: imageUrl.isEmpty
          ? Icon(
              icon,
              color: AppColors.secondary,
              size: 42,
            )
          : Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) {
                return Icon(
                  icon,
                  color: AppColors.secondary,
                  size: 42,
                );
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) {
                  return child;
                }

                return const Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                );
              },
            ),
    );
  }
}

class _HeroTypeBadge extends StatelessWidget {
  const _HeroTypeBadge({
    required this.typeLabel,
  });

  final String typeLabel;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.13),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.10),
          ),
        ),
        child: Text(
          typeLabel,
          textAlign: TextAlign.right,
          style: const TextStyle(
            color: Color(0xFFE8F3EF),
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _ItemInfoCard extends StatelessWidget {
  const _ItemInfoCard({
    required this.item,
    required this.typeLabel,
  });

  final LibraryItemSummary item;
  final String typeLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _InfoTile(
            title: 'السعر',
            value: item.priceLabel,
            icon: Icons.payments_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _InfoTile(
            title: 'التصنيف',
            value: item.categoryName,
            icon: Icons.category_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _InfoTile(
            title: 'النوع',
            value: typeLabel,
            icon: Icons.widgets_rounded,
          ),
        ),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderSoft),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppColors.primary, size: 22),
          ),
          const Spacer(),
          Text(
            value,
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 13,
              height: 1.15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              height: 1.2,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemDescriptionCard extends StatelessWidget {
  const _ItemDescriptionCard({
    required this.item,
  });

  final LibraryItemSummary item;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.borderSoft),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 18,
            offset: Offset(0, 9),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const Row(
            children: [
              Spacer(),
              Text(
                'الوصف',
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(width: 10),
              Icon(
                Icons.notes_rounded,
                color: AppColors.primary,
                size: 22,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            item.description,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 14,
              height: 1.75,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemActionCard extends StatelessWidget {
  const _ItemActionCard({
    required this.item,
  });

  final LibraryItemSummary item;

  Future<void> _handleTap(BuildContext context) async {
    if (item.isFree) {
      if (item.fileUrl.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'رابط الملف غير متوفر حاليًا',
              textAlign: TextAlign.right,
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.danger,
          ),
        );

        return;
      }

      final uri = Uri.tryParse(item.fileUrl);

      if (uri == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'تعذر فتح الملف الآن',
              textAlign: TextAlign.right,
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.danger,
          ),
        );

        return;
      }

      final didLaunch = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!context.mounted) {
        return;
      }

      if (!didLaunch) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'تعذر فتح الملف الآن',
              textAlign: TextAlign.right,
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.danger,
          ),
        );
      }

      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CartScreen(
          initialItem: item,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = item.isFree ? 'فتح العنصر' : 'إضافة إلى السلة';
    final icon = item.isFree
        ? Icons.open_in_new_rounded
        : Icons.add_shopping_cart_rounded;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.borderSoft),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 18,
            offset: Offset(0, 9),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          _handleTap(context);
        },
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.18),
                blurRadius: 18,
                offset: const Offset(0, 9),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                icon,
                color: Colors.white,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LibraryItemFavoriteService {
  LibraryItemFavoriteService({
    ApiClient? apiClient,
    TokenStorage? tokenStorage,
  })  : _apiClient = apiClient ?? ApiClient(),
        _tokenStorage = tokenStorage ?? TokenStorage();

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  Future<bool> isLibraryItemFavorite(int itemId) async {
    try {
      final token = await _tokenStorage.getToken();

      final response = await _apiClient.get(
        '${ApiEndpoints.favorites}?type=library_item',
        token: token,
      );

      if (response['success'] != true) {
        return false;
      }

      final items = _extractItems(response);

      for (final item in items) {
        if (item is Map<String, dynamic>) {
          final favoriteId = _asInt(
            item['favoritable_id'] ??
                item['favoriteable_id'] ??
                item['library_item_id'] ??
                item['item_id'] ??
                item['id'],
            fallback: 0,
          );

          final type = item['type']?.toString();

          if ((type == null || type == 'library_item') &&
              favoriteId == itemId) {
            return true;
          }
        }
      }

      return false;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>> toggleLibraryItem(int itemId) async {
    try {
      final token = await _tokenStorage.getToken();

      return _apiClient.post(
        ApiEndpoints.favoritesToggle,
        token: token,
        body: {
          'type': 'library_item',
          'id': itemId,
          'favoritable_id': itemId,
        },
      );
    } catch (_) {
      return {
        'success': false,
        'message': 'تعذر تحديث المفضلة الآن',
      };
    }
  }

  List<dynamic> _extractItems(Map<String, dynamic> response) {
    final data = response['data'];

    if (data is List) {
      return data;
    }

    if (data is Map<String, dynamic>) {
      final directData = data['data'];
      final items = data['items'];
      final favorites = data['favorites'];

      if (directData is List) {
        return directData;
      }

      if (items is List) {
        return items;
      }

      if (favorites is List) {
        return favorites;
      }
    }

    return <dynamic>[];
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
        child: Icon(icon, color: AppColors.text, size: 20),
      ),
    );
  }
}
