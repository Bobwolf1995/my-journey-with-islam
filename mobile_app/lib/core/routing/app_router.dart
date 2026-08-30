import 'package:flutter/material.dart';

import 'route_names.dart';

class AppRouter {
  const AppRouter._();

  static String get initialRoute => RouteNames.home;

  static bool isKnownRoute(String? routeName) {
    if (routeName == null) {
      return false;
    }

    return routeTitles.containsKey(routeName);
  }

  static String titleOf(String? routeName) {
    return routeTitles[routeName] ?? 'صفحة غير معروفة';
  }

  static Route<dynamic> unknownRoute(RouteSettings settings) {
    return MaterialPageRoute<void>(
      settings: settings,
      builder: (_) => _UnknownRoutePage(
        routeName: settings.name,
      ),
    );
  }

  static const Map<String, String> routeTitles = {
    RouteNames.splash: 'البداية',
    RouteNames.onboarding: 'التعريف بالتطبيق',
    RouteNames.login: 'تسجيل الدخول',
    RouteNames.register: 'إنشاء حساب',
    RouteNames.shell: 'التطبيق',
    RouteNames.home: 'الرئيسية',
    RouteNames.journey: 'رحلتي',
    RouteNames.courses: 'الدورات',
    RouteNames.courseDetails: 'تفاصيل الدورة',
    RouteNames.lessonDetails: 'تفاصيل الدرس',
    RouteNames.library: 'المكتبة',
    RouteNames.libraryItemDetails: 'تفاصيل عنصر المكتبة',
    RouteNames.cart: 'السلة',
    RouteNames.orders: 'طلباتي',
    RouteNames.community: 'المجتمع',
    RouteNames.communityPostDetails: 'تفاصيل المنشور',
    RouteNames.communityGroupDetails: 'تفاصيل المجموعة',
    RouteNames.conversations: 'المحادثات',
    RouteNames.chat: 'المحادثة',
    RouteNames.notifications: 'الإشعارات',
    RouteNames.profile: 'ملفي',
    RouteNames.editProfile: 'تعديل الملف الشخصي',
    RouteNames.favorites: 'المفضلة',
    RouteNames.badges: 'الشارات',
    RouteNames.tasks: 'المهام',
    RouteNames.mentor: 'المرشد',
    RouteNames.aiAssistant: 'المساعد الذكي',
  };
}

class _UnknownRoutePage extends StatelessWidget {
  const _UnknownRoutePage({
    this.routeName,
  });

  final String? routeName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              routeName == null
                  ? 'هذه الصفحة غير متاحة'
                  : 'هذه الصفحة غير متاحة: $routeName',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
