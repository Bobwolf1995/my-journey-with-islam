class BadgeItem {
  const BadgeItem({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.points,
    required this.earnedAt,
  });

  final int id;
  final String title;
  final String description;
  final String icon;
  final String color;
  final int points;
  final String earnedAt;

  factory BadgeItem.fromJson(Map<String, dynamic> json) {
    final pivot = json['pivot'];

    return BadgeItem(
      id: _toInt(json['id']),
      title: _toString(
        json['name_ar'] ?? json['title_ar'] ?? json['title'] ?? json['name'],
        fallback: 'وسام',
      ),
      description: _toString(
        json['description_ar'] ?? json['description'],
      ),
      icon: _toString(
        json['icon'],
        fallback: 'emoji_events',
      ),
      color: _toString(
        json['color'],
        fallback: '#0F766E',
      ),
      points: _toInt(
        json['points'] ??
            json['required_points'] ??
            json['reward_points'] ??
            json['score'],
      ),
      earnedAt: _toString(
        pivot is Map<String, dynamic>
            ? pivot['created_at'] ?? pivot['earned_at']
            : json['earned_at'] ?? json['created_at'],
      ),
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String _toString(dynamic value, {String fallback = ''}) {
    final text = value?.toString().trim();

    if (text == null || text.isEmpty) {
      return fallback;
    }

    return text;
  }
}

class BadgesResult {
  const BadgesResult({
    required this.badges,
    required this.message,
    required this.isFromServer,
  });

  final List<BadgeItem> badges;
  final String message;
  final bool isFromServer;

  factory BadgesResult.fromResponse(Map<String, dynamic> response) {
    final items = _extractItems(response['data']);

    return BadgesResult(
      badges: items
          .whereType<Map<String, dynamic>>()
          .map(BadgeItem.fromJson)
          .toList(),
      message: response['message']?.toString() ?? 'تم جلب الأوسمة بنجاح',
      isFromServer: response['success'] == true,
    );
  }

  factory BadgesResult.fallback() {
    return const BadgesResult(
      isFromServer: false,
      message: 'تعذر الاتصال بالسيرفر',
      badges: [
        BadgeItem(
          id: 1,
          title: 'وسام البداية',
          description: 'أكملت خطواتك الأولى في رحلة التعلم.',
          icon: 'stars',
          color: '#0F766E',
          points: 50,
          earnedAt: '',
        ),
        BadgeItem(
          id: 2,
          title: 'طالب مجتهد',
          description: 'أكملت عدة مهام تعليمية بنجاح.',
          icon: 'school',
          color: '#2563EB',
          points: 120,
          earnedAt: '',
        ),
        BadgeItem(
          id: 3,
          title: 'رفيق القرآن',
          description: 'داومت على قراءة المحتوى التعليمي.',
          icon: 'menu_book',
          color: '#B45309',
          points: 90,
          earnedAt: '',
        ),
      ],
    );
  }

  static List<dynamic> _extractItems(dynamic data) {
    if (data is List) {
      return data;
    }

    if (data is Map<String, dynamic>) {
      final directBadges = data['badges'];
      final directItems = data['items'];
      final paginatedData = data['data'];

      if (directBadges is List) {
        return directBadges;
      }

      if (directItems is List) {
        return directItems;
      }

      if (paginatedData is List) {
        return paginatedData;
      }

      if (directBadges is Map<String, dynamic>) {
        return _extractItems(directBadges);
      }

      if (paginatedData is Map<String, dynamic>) {
        return _extractItems(paginatedData);
      }
    }

    return <dynamic>[];
  }
}
