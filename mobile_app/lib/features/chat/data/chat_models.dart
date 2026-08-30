class ConversationSummary {
  const ConversationSummary({
    required this.id,
    required this.title,
    required this.type,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.participantName,
  });

  final int id;
  final String title;
  final String type;
  final String lastMessage;
  final String lastMessageAt;
  final String participantName;

  factory ConversationSummary.fromJson(Map<String, dynamic> json) {
    final latestMessage = json['latest_message'] ?? json['last_message'];
    final type = _toString(json['type'], fallback: 'mentor');
    final participantName = _extractParticipantName(json);

    return ConversationSummary(
      id: _toInt(json['id']),
      title: _toString(
        json['title'] ?? json['name'] ?? json['subject'],
        fallback:
            participantName.isNotEmpty ? participantName : _typeTitle(type),
      ),
      type: type,
      lastMessage: latestMessage is Map<String, dynamic>
          ? _toString(
              latestMessage['body'] ??
                  latestMessage['message'] ??
                  latestMessage['content'] ??
                  latestMessage['text'],
              fallback: 'ابدأ المحادثة الآن',
            )
          : _toString(
              json['last_message_text'] ??
                  json['last_message'] ??
                  json['message_preview'],
              fallback: 'ابدأ المحادثة الآن',
            ),
      lastMessageAt: latestMessage is Map<String, dynamic>
          ? _toString(
              latestMessage['created_at'] ??
                  latestMessage['sent_at'] ??
                  json['last_message_at'] ??
                  json['updated_at'] ??
                  json['created_at'],
            )
          : _toString(
              json['last_message_at'] ??
                  json['updated_at'] ??
                  json['created_at'],
            ),
      participantName: participantName,
    );
  }

  static String _extractParticipantName(Map<String, dynamic> json) {
    final directName = _toString(
      json['participant_name'] ??
          json['mentor_name'] ??
          json['support_name'] ??
          json['user_name'],
    );

    if (directName.isNotEmpty) {
      return directName;
    }

    final participant =
        json['participant'] ?? json['mentor'] ?? json['support'];

    if (participant is Map<String, dynamic>) {
      final name = _extractUserName(participant);

      if (name.isNotEmpty) {
        return name;
      }
    }

    final participants = json['participants'];

    if (participants is List && participants.isNotEmpty) {
      for (final item in participants) {
        if (item is! Map<String, dynamic>) {
          continue;
        }

        final name = _extractUserName(item);

        if (name.isNotEmpty) {
          return name;
        }
      }
    }

    return 'المرشد';
  }

  static String _extractUserName(Map<String, dynamic> json) {
    final directName = _toString(json['name'] ?? json['display_name']);

    if (directName.isNotEmpty) {
      return directName;
    }

    final user = json['user'];

    if (user is Map<String, dynamic>) {
      return _toString(user['name'] ?? user['display_name']);
    }

    return '';
  }

  static String _typeTitle(dynamic type) {
    switch (_toString(type)) {
      case 'support':
        return 'الدعم';
      case 'admin':
        return 'الإدارة';
      case 'mentor':
      default:
        return 'المرشد';
    }
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

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.body,
    required this.messageType,
    required this.createdAt,
  });

  final int id;
  final int senderId;
  final String senderName;
  final String body;
  final String messageType;
  final String createdAt;

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final sender = json['sender'] ?? json['user'] ?? json['from_user'];
    final isMine = json['is_mine'] == true ||
        json['mine'] == true ||
        json['from_me'] == true;

    return ChatMessage(
      id: _toInt(json['id']),
      senderId: isMine
          ? -1
          : _toInt(
              json['sender_id'] ??
                  json['user_id'] ??
                  json['from_user_id'] ??
                  json['created_by'],
            ),
      senderName: isMine
          ? 'أنت'
          : sender is Map<String, dynamic>
              ? _toString(
                  sender['name'] ?? sender['display_name'],
                  fallback: 'المرشد',
                )
              : _toString(
                  json['sender_name'] ?? json['user_name'],
                  fallback: 'المرشد',
                ),
      body: _toString(
        json['body'] ?? json['message'] ?? json['content'] ?? json['text'],
        fallback: 'رسالة جديدة',
      ),
      messageType: _toString(
        json['message_type'] ?? json['type'],
        fallback: 'text',
      ),
      createdAt: _toString(
        json['created_at'] ?? json['sent_at'] ?? json['time'],
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

class ConversationsResult {
  const ConversationsResult({
    required this.conversations,
    required this.message,
    required this.isFromServer,
  });

  final List<ConversationSummary> conversations;
  final String message;
  final bool isFromServer;

  factory ConversationsResult.fromResponse(Map<String, dynamic> response) {
    final items = _extractItems(
      response['data'],
      primaryKeys: const [
        'conversations',
        'items',
        'data',
      ],
    );

    return ConversationsResult(
      conversations: items
          .whereType<Map<String, dynamic>>()
          .map(ConversationSummary.fromJson)
          .toList(),
      message: response['message']?.toString() ?? 'تم جلب المحادثات بنجاح',
      isFromServer: response['success'] == true,
    );
  }

  factory ConversationsResult.fallback() {
    return const ConversationsResult(
      isFromServer: false,
      message: 'تعذر الاتصال بالسيرفر',
      conversations: [
        ConversationSummary(
          id: 1,
          title: 'المرشد',
          type: 'mentor',
          lastMessage: 'السلام عليكم، كيف يمكنني مساعدتك اليوم؟',
          lastMessageAt: '',
          participantName: 'المرشد',
        ),
      ],
    );
  }
}

class MessagesResult {
  const MessagesResult({
    required this.messages,
    required this.message,
    required this.isFromServer,
  });

  final List<ChatMessage> messages;
  final String message;
  final bool isFromServer;

  factory MessagesResult.fromResponse(Map<String, dynamic> response) {
    final items = _extractItems(
      response['data'],
      primaryKeys: const [
        'messages',
        'items',
        'data',
      ],
    );

    return MessagesResult(
      messages: items
          .whereType<Map<String, dynamic>>()
          .map(ChatMessage.fromJson)
          .toList()
          .reversed
          .toList(),
      message: response['message']?.toString() ?? 'تم جلب الرسائل بنجاح',
      isFromServer: response['success'] == true,
    );
  }

  factory MessagesResult.fallback() {
    return const MessagesResult(
      isFromServer: false,
      message: 'تعذر الاتصال بالسيرفر',
      messages: [
        ChatMessage(
          id: 1,
          senderId: 0,
          senderName: 'المرشد',
          body: 'السلام عليكم ورحمة الله وبركاته، كيف تسير رحلتك اليوم؟',
          messageType: 'text',
          createdAt: '',
        ),
        ChatMessage(
          id: 2,
          senderId: -1,
          senderName: 'أنت',
          body: 'الحمد لله، أريد نصيحة للاستمرار على التعلم.',
          messageType: 'text',
          createdAt: '',
        ),
        ChatMessage(
          id: 3,
          senderId: 0,
          senderName: 'المرشد',
          body:
              'ابدأ بخطوة صغيرة ثابتة كل يوم، واستعن بالله ولا تستعجل النتائج.',
          messageType: 'text',
          createdAt: '',
        ),
      ],
    );
  }
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
