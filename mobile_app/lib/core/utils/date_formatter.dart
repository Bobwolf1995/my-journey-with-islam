class DateFormatter {
  const DateFormatter._();

  static String shortDate(DateTime date) {
    final localDate = date.toLocal();

    return '${_twoDigits(localDate.day)}/${_twoDigits(localDate.month)}/${localDate.year}';
  }

  static String dateTime(DateTime date) {
    final localDate = date.toLocal();

    return '${shortDate(localDate)} - ${time(localDate)}';
  }

  static String time(DateTime date) {
    final localDate = date.toLocal();
    final hour = localDate.hour;
    final minute = _twoDigits(localDate.minute);
    final period = hour >= 12 ? 'م' : 'ص';
    final displayHour = hour == 0
        ? 12
        : hour > 12
            ? hour - 12
            : hour;

    return '$displayHour:$minute $period';
  }

  static String relative(DateTime date) {
    final now = DateTime.now();
    final localDate = date.toLocal();
    final today = DateTime(now.year, now.month, now.day);
    final targetDay = DateTime(
      localDate.year,
      localDate.month,
      localDate.day,
    );

    final dayDifference = today.difference(targetDay).inDays;

    if (dayDifference == 0) {
      return 'اليوم';
    }

    if (dayDifference == 1) {
      return 'أمس';
    }

    if (dayDifference > 1 && dayDifference < 7) {
      return 'منذ $dayDifference أيام';
    }

    if (dayDifference >= 7 && dayDifference < 30) {
      final weeks = (dayDifference / 7).floor();

      if (weeks == 1) {
        return 'منذ أسبوع';
      }

      return 'منذ $weeks أسابيع';
    }

    return shortDate(localDate);
  }

  static String fromIsoDate(
    String? value, {
    String fallback = '',
  }) {
    if (value == null || value.trim().isEmpty) {
      return fallback;
    }

    final date = DateTime.tryParse(value.trim());

    if (date == null) {
      return fallback;
    }

    return shortDate(date);
  }

  static String relativeFromIsoDate(
    String? value, {
    String fallback = '',
  }) {
    if (value == null || value.trim().isEmpty) {
      return fallback;
    }

    final date = DateTime.tryParse(value.trim());

    if (date == null) {
      return fallback;
    }

    return relative(date);
  }

  static String _twoDigits(int value) {
    return value.toString().padLeft(2, '0');
  }
}
