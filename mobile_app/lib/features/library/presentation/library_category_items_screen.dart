import 'package:flutter/material.dart';

import '../../../shared/theme/app_colors.dart';
import '../data/library_item_summary.dart';
import '../data/library_service.dart';
import '../library_item_details_screen.dart';

class LibraryCategoryItemsScreen extends StatefulWidget {
  const LibraryCategoryItemsScreen({
    super.key,
    required this.title,
    required this.types,
    this.categorySlug,
  });

  final String title;
  final List<String> types;
  final String? categorySlug;

  @override
  State<LibraryCategoryItemsScreen> createState() =>
      _LibraryCategoryItemsScreenState();
}

class _LibraryCategoryItemsScreenState
    extends State<LibraryCategoryItemsScreen> {
  final LibraryService _libraryService = LibraryService();

  late Future<LibraryResult> _itemsFuture;

  @override
  void initState() {
    super.initState();
    _itemsFuture = _loadItems();
  }

  Future<LibraryResult> _loadItems() {
    return _libraryService.getItems(
      categorySlug: widget.categorySlug,
    );
  }

  Future<void> _refresh() async {
    setState(() {
      _itemsFuture = _loadItems();
    });

    await _itemsFuture;
  }

  List<LibraryItemSummary> _filterItems(List<LibraryItemSummary> items) {
    final categorySlug = widget.categorySlug?.trim() ?? '';

    if (categorySlug.isNotEmpty) {
      return items;
    }

    return items.where((item) {
      final itemType = item.type.toLowerCase();

      return widget.types.any(
        (type) => itemType.contains(type.toLowerCase()),
      );
    }).toList();
  }

  void _openDetails(LibraryItemSummary item) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LibraryItemDetailsScreen(item: item),
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
          child: FutureBuilder<LibraryResult>(
            future: _itemsFuture,
            builder: (context, snapshot) {
              final isLoading =
                  snapshot.connectionState == ConnectionState.waiting;

              final result = snapshot.data;
              final items = result == null
                  ? <LibraryItemSummary>[]
                  : _filterItems(result.items);

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
                      _CategoryHeader(title: widget.title),
                      const SizedBox(height: 18),
                      _CategoryIntro(title: widget.title),
                      const SizedBox(height: 18),
                      if (isLoading && result == null)
                        const _LoadingCard()
                      else if (items.isEmpty)
                        const _EmptyCategoryCard()
                      else
                        _CategoryItemsGrid(
                          items: items,
                          onItemTap: _openDetails,
                        ),
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

class _CategoryHeader extends StatelessWidget {
  const _CategoryHeader({
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _CircleButton(
          icon: Icons.arrow_back_ios_new_rounded,
          onTap: () => Navigator.of(context).pop(),
        ),
        const Spacer(),
        Column(
          children: [
            Text(
              title,
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 23,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 3),
            const Text(
              'محتوى المكتبة',
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

class _CategoryIntro extends StatelessWidget {
  const _CategoryIntro({
    required this.title,
  });

  final String title;

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
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.widgets_rounded,
              color: AppColors.primary,
              size: 30,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'استعرض عناصر هذا القسم من المكتبة.',
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

class _CategoryItemsGrid extends StatelessWidget {
  const _CategoryItemsGrid({
    required this.items,
    required this.onItemTap,
  });

  final List<LibraryItemSummary> items;
  final ValueChanged<LibraryItemSummary> onItemTap;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      itemCount: items.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.78,
      ),
      itemBuilder: (context, index) {
        return _CategoryItemCard(
          item: items[index],
          onTap: () => onItemTap(items[index]),
        );
      },
    );
  }
}

class _CategoryItemCard extends StatelessWidget {
  const _CategoryItemCard({
    required this.item,
    required this.onTap,
  });

  final LibraryItemSummary item;
  final VoidCallback onTap;

  IconData get _icon {
    final type = item.type.toLowerCase();

    if (type.contains('audio')) {
      return Icons.headphones_rounded;
    }

    if (type.contains('pdf')) {
      return Icons.picture_as_pdf_rounded;
    }

    if (type.contains('gift')) {
      return Icons.redeem_rounded;
    }

    if (type.contains('product')) {
      return Icons.card_giftcard_rounded;
    }

    if (type.contains('video') || type.contains('course')) {
      return Icons.video_library_rounded;
    }

    return Icons.menu_book_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(12),
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: item.coverImageUrl.isEmpty
                    ? Container(
                        color: AppColors.surfaceMuted,
                        child: Icon(
                          _icon,
                          color: AppColors.secondary,
                          size: 42,
                        ),
                      )
                    : Image.network(
                        item.coverImageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) {
                          return Container(
                            color: AppColors.surfaceMuted,
                            child: Icon(
                              _icon,
                              color: AppColors.secondary,
                              size: 42,
                            ),
                          );
                        },
                      ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              item.title,
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 13,
                height: 1.35,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              item.priceLabel,
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
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
      height: 180,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: const CircularProgressIndicator(
        color: AppColors.primary,
        strokeWidth: 2.6,
      ),
    );
  }
}

class _EmptyCategoryCard extends StatelessWidget {
  const _EmptyCategoryCard();

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
            Icons.inventory_2_outlined,
            color: AppColors.textMuted,
            size: 42,
          ),
          SizedBox(height: 12),
          Text(
            'لا يوجد محتوى في هذا القسم حاليًا',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.text,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'اسحب للأسفل لتحديث المحتوى أو جرّب قسمًا آخر.',
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
