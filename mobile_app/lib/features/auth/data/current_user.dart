class CurrentUser {
  const CurrentUser({
    required this.name,
    required this.email,
    required this.role,
    required this.level,
    required this.points,
    required this.badgesCount,
    required this.lessonsCount,
    required this.phone,
    required this.country,
    required this.city,
    required this.language,
  });

  final String name;
  final String email;
  final String role;
  final String level;
  final int points;
  final int badgesCount;
  final int lessonsCount;
  final String phone;
  final String country;
  final String city;
  final String language;

  factory CurrentUser.fallback() {
    return const CurrentUser(
      name: 'أحمد محمد',
      email: '',
      role: 'طالب علم',
      level: 'المستوى 2',
      points: 650,
      badgesCount: 7,
      lessonsCount: 12,
      phone: '',
      country: '',
      city: '',
      language: 'ar',
    );
  }

  factory CurrentUser.fromResponse(Map<String, dynamic> response) {
    final data = response['data'];

    if (data is! Map<String, dynamic>) {
      return CurrentUser.fallback();
    }

    final user = data['user'] is Map<String, dynamic>
        ? data['user'] as Map<String, dynamic>
        : data;

    final profile = user['profile'] is Map<String, dynamic>
        ? user['profile'] as Map<String, dynamic>
        : <String, dynamic>{};

    final level = profile['current_level'] is Map<String, dynamic>
        ? profile['current_level'] as Map<String, dynamic>
        : profile['level'] is Map<String, dynamic>
            ? profile['level'] as Map<String, dynamic>
            : <String, dynamic>{};

    final points = profile['total_points'] ?? profile['points'];

    return CurrentUser(
      name: _string(
        profile['display_name'] ?? user['name'],
        fallback: 'أحمد محمد',
      ),
      email: _string(user['email']),
      role: _string(profile['role'], fallback: 'طالب علم'),
      level: _string(
        level['name_ar'] ?? profile['rank'] ?? profile['level'],
        fallback: 'المستوى 2',
      ),
      points: _int(points, fallback: 650),
      badgesCount: _int(data['badges_count'], fallback: 7),
      lessonsCount: _int(data['lessons_count'], fallback: 12),
      phone: _string(user['phone'] ?? profile['phone']),
      country: _string(profile['country']),
      city: _string(profile['city']),
      language: _string(profile['language'], fallback: 'ar'),
    );
  }

  static String _string(dynamic value, {String fallback = ''}) {
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }

    return fallback;
  }

  static int _int(dynamic value, {required int fallback}) {
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
