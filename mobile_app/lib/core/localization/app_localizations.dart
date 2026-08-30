class AppLocalizations {
  const AppLocalizations._();

  static const String appName = 'رحلتي مع الإسلام';

  static const String home = 'الرئيسية';
  static const String journey = 'رحلتي';
  static const String courses = 'دوراتي';
  static const String library = 'المكتبة';
  static const String community = 'المجتمع';
  static const String profile = 'ملفي';

  static const String login = 'تسجيل الدخول';
  static const String register = 'إنشاء حساب';
  static const String logout = 'تسجيل الخروج';

  static const String notifications = 'الإشعارات';
  static const String favorites = 'المفضلة';
  static const String tasks = 'المهام';
  static const String badges = 'الشارات';
  static const String mentor = 'المرشد';
  static const String aiAssistant = 'المساعد الذكي';

  static const String loading = 'جاري التحميل...';
  static const String retry = 'إعادة المحاولة';
  static const String refresh = 'تحديث';
  static const String save = 'حفظ';
  static const String cancel = 'إلغاء';
  static const String confirm = 'تأكيد';
  static const String delete = 'حذف';
  static const String edit = 'تعديل';
  static const String close = 'إغلاق';

  static const String noData = 'لا توجد بيانات حاليًا';
  static const String connectionError = 'تعذر الاتصال بالسيرفر';
  static const String unexpectedError = 'حدث خطأ غير متوقع';
  static const String tryAgainLater = 'حاول مرة أخرى لاحقًا';

  static String lessonNumber(int number) {
    return 'الدرس $number';
  }

  static String lessonsCount(int count) {
    return '$count درس';
  }

  static String minutesCount(int count) {
    return '$count دقيقة';
  }

  static String pointsCount(int count) {
    return '$count نقطة';
  }

  static String completedPercent(int percent) {
    return '$percent% مكتمل';
  }
}
