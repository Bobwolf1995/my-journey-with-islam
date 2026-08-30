class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.isRead,
    required this.createdAt,
  });

  final int id;
  final String title;
  final String body;
  final String type;
  final bool isRead;
  final String createdAt;

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: _toInt(json['id']),
      title: _toString(
        json['title_ar'] ?? json['title'] ?? json['subject'] ?? json['heading'],
        fallback: 'إشعار جديد',
      ),
      body: _toString(
        json['body_ar'] ??
            json['body'] ??
            json['message'] ??
            json['content'] ??
            json['text'],
        fallback: 'لديك تحديث جديد في رحلتك.',
      ),
      type: _toString(
        json['type'] ?? json['notification_type'] ?? json['category'],
        fallback: 'general',
      ),
      isRead: json['read_at'] != null ||
          json['is_read'] == true ||
          json['isRead'] == true ||
          json['read'] == true,
      createdAt: _toString(
        json['created_at'] ?? json['createdAt'] ?? json['date'],
      ),
    );
  }

  NotificationItem copyWith({
    bool? isRead,
  }) {
    return NotificationItem(
      id: id,
      title: title,
      body: body,
      type: type,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
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

class NotificationsResult {
  const NotificationsResult({
    required this.notifications,
    required this.message,
    required this.isFromServer,
  });

  final List<NotificationItem> notifications;
  final String message;
  final bool isFromServer;

  factory NotificationsResult.fromResponse(Map<String, dynamic> response) {
    final items = _extractItems(response['data']);

    return NotificationsResult(
      notifications: items
          .whereType<Map<String, dynamic>>()
          .map(NotificationItem.fromJson)
          .where((notification) => notification.id > 0)
          .toList(),
      message: response['message']?.toString() ?? 'تم جلب الإشعارات بنجاح',
      isFromServer: response['success'] == true,
    );
  }

  factory NotificationsResult.fallback() {
    return const NotificationsResult(
      isFromServer: false,
      message: 'تعذر الاتصال بالسيرفر',
      notifications: [
        NotificationItem(
          id: 0,
          title: 'مرحبًا بك في رحلتي مع الإسلام',
          body: 'ابدأ يومك بدرس قصير ومهمة بسيطة تقربك أكثر من هدفك.',
          type: 'welcome',
          isRead: true,
          createdAt: '',
        ),
        NotificationItem(
          id: 0,
          title: 'مهمة اليوم جاهزة',
          body: 'أكمل مهمة اليوم لتحصل على نقاط جديدة في رحلتك.',
          type: 'task',
          isRead: true,
          createdAt: '',
        ),
      ],
    );
  }

  static List<dynamic> _extractItems(dynamic data) {
    if (data is List) {
      return data;
    }

    if (data is Map<String, dynamic>) {
      final directData = data['data'];
      final notifications = data['notifications'];
      final items = data['items'];

      if (directData is List) {
        return directData;
      }

      if (notifications is List) {
        return notifications;
      }

      if (items is List) {
        return items;
      }

      if (directData is Map<String, dynamic>) {
        return _extractItems(directData);
      }
    }

    return <dynamic>[];
  }
}
