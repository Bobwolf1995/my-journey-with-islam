class LibraryItemSummary {
  const LibraryItemSummary({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.categoryName,
    required this.price,
    required this.isFree,
    this.coverImageUrl = '',
    this.fileUrl = '',
  });

  final int id;
  final String title;
  final String description;
  final String type;
  final String categoryName;
  final double price;
  final bool isFree;
  final String coverImageUrl;
  final String fileUrl;

  String get priceLabel {
    if (isFree || price <= 0) {
      return 'مجاني';
    }

    return '\$${price.toStringAsFixed(0)}';
  }

  factory LibraryItemSummary.fallback({
    required int id,
    required String title,
    required String description,
    required String type,
    required String categoryName,
    required double price,
    required bool isFree,
    String coverImageUrl = '',
    String fileUrl = '',
  }) {
    return LibraryItemSummary(
      id: id,
      title: title,
      description: description,
      type: type,
      categoryName: categoryName,
      price: price,
      isFree: isFree,
      coverImageUrl: coverImageUrl,
      fileUrl: fileUrl,
    );
  }

  factory LibraryItemSummary.fromJson(Map<String, dynamic> json) {
    final category = _map(json['category'] ?? json['library_category']);

    final price = _double(
      json['price'] ??
          json['amount'] ??
          json['sale_price'] ??
          json['regular_price'],
      fallback: 0,
    );

    return LibraryItemSummary(
      id: _int(json['id'], fallback: 0),
      title: _string(
        json['title_ar'] ?? json['name_ar'] ?? json['title'] ?? json['name'],
        fallback: 'عنصر من المكتبة',
      ),
      description: _string(
        json['description_ar'] ??
            json['short_description_ar'] ??
            json['description'] ??
            json['summary'],
        fallback: 'محتوى نافع يساعدك في رحلتك التعليمية.',
      ),
      type: _string(
        json['item_type'] ?? json['type'] ?? json['content_type'],
        fallback: 'book',
      ),
      categoryName: _string(
        category['name_ar'] ??
            category['title_ar'] ??
            category['name'] ??
            category['title'] ??
            json['category_name'],
        fallback: 'المكتبة',
      ),
      price: price,
      isFree: json['is_free'] == true ||
          json['free'] == true ||
          _string(json['price_type'], fallback: '') == 'free' ||
          price <= 0,
      coverImageUrl: _string(
        json['cover_image_url'] ?? json['cover_image'] ?? json['thumbnail'],
        fallback: '',
      ),
      fileUrl: _string(
        json['file_url'] ?? json['file_path'],
        fallback: '',
      ),
    );
  }
}

class LibraryResult {
  const LibraryResult({
    required this.items,
  });

  final List<LibraryItemSummary> items;

  factory LibraryResult.fallback() {
    return LibraryResult(
      items: [
        LibraryItemSummary.fallback(
          id: 0,
          title: 'مختصر فهم التفسير',
          description: 'كتاب ميسر للمبتدئين في فهم معاني القرآن.',
          type: 'book',
          categoryName: 'كتب',
          price: 25,
          isFree: false,
        ),
        LibraryItemSummary.fallback(
          id: 0,
          title: 'كتاب شمائل النبي',
          description: 'تعرف على أخلاق النبي صلى الله عليه وسلم.',
          type: 'book',
          categoryName: 'كتب',
          price: 15,
          isFree: false,
        ),
        LibraryItemSummary.fallback(
          id: 0,
          title: 'دعوة مسلم جديد',
          description: 'مادة صوتية مختصرة للتعريف بأساسيات الإسلام.',
          type: 'audio',
          categoryName: 'صوتيات',
          price: 0,
          isFree: true,
        ),
      ],
    );
  }

  factory LibraryResult.fromResponse(Map<String, dynamic> response) {
    final itemsData = _extractItems(response['data']);

    final items = itemsData
        .whereType<Map<String, dynamic>>()
        .map(LibraryItemSummary.fromJson)
        .where((item) => item.id > 0)
        .toList();

    if (items.isEmpty) {
      return LibraryResult.fallback();
    }

    return LibraryResult(items: items);
  }

  static List<dynamic> _extractItems(dynamic data) {
    if (data is List) {
      return data;
    }

    if (data is Map<String, dynamic>) {
      final directData = data['data'];
      final items = data['items'];
      final libraryItems = data['library_items'];

      if (directData is List) {
        return directData;
      }

      if (items is List) {
        return items;
      }

      if (libraryItems is List) {
        return libraryItems;
      }

      if (directData is Map<String, dynamic>) {
        return _extractItems(directData);
      }
    }

    return <dynamic>[];
  }
}

Map<String, dynamic> _map(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }

  return <String, dynamic>{};
}

String _string(dynamic value, {required String fallback}) {
  if (value is String && value.trim().isNotEmpty) {
    return value.trim();
  }

  return fallback;
}

int _int(dynamic value, {required int fallback}) {
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

double _double(dynamic value, {required double fallback}) {
  if (value is double) {
    return value;
  }

  if (value is int) {
    return value.toDouble();
  }

  if (value is num) {
    return value.toDouble();
  }

  if (value is String) {
    return double.tryParse(value) ?? fallback;
  }

  return fallback;
}
