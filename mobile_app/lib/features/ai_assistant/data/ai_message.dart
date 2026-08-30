class AiMessage {
  const AiMessage({
    required this.id,
    required this.body,
    required this.isUser,
    required this.needsSpecialist,
    required this.suggestedAction,
  });

  final int id;
  final String body;
  final bool isUser;
  final bool needsSpecialist;
  final String suggestedAction;

  factory AiMessage.user(String question) {
    return AiMessage(
      id: DateTime.now().microsecondsSinceEpoch,
      body: question,
      isUser: true,
      needsSpecialist: false,
      suggestedAction: '',
    );
  }

  factory AiMessage.assistant({
    required Map<String, dynamic> response,
  }) {
    final data = response['data'];

    if (data is Map<String, dynamic>) {
      return AiMessage(
        id: _toInt(data['log_id']),
        body: _toString(
          data['answer'],
          fallback: 'تمت معالجة سؤالك بنجاح.',
        ),
        isUser: false,
        needsSpecialist: data['needs_specialist'] == true,
        suggestedAction: _toString(data['suggested_action']),
      );
    }

    return const AiMessage(
      id: 0,
      body: 'تمت معالجة سؤالك بنجاح.',
      isUser: false,
      needsSpecialist: false,
      suggestedAction: '',
    );
  }

  factory AiMessage.fallbackAnswer() {
    return const AiMessage(
      id: 0,
      body: 'تعذر الاتصال بالمساعد الآن. حاول مرة أخرى بعد قليل.',
      isUser: false,
      needsSpecialist: false,
      suggestedAction: '',
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
