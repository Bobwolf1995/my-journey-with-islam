import 'package:flutter/material.dart';

import '../../../shared/theme/app_colors.dart';
import '../../community/presentation/community_page.dart';
import '../../courses/presentation/courses_page.dart';
import '../../home/presentation/home_page.dart';
import '../../library/presentation/library_page.dart';
import '../../profile/presentation/profile_page.dart';

class RihlatiShell extends StatefulWidget {
  const RihlatiShell({super.key});

  @override
  State<RihlatiShell> createState() => _RihlatiShellState();
}

class _RihlatiShellState extends State<RihlatiShell> {
  static const int _homeIndex = 0;

  static const int _profileIndex = 4;

  int _currentIndex = _homeIndex;

  void _goToTab(int index) {
    if (_currentIndex == index) {
      return;
    }

    setState(() {
      _currentIndex = index;
    });
  }

  List<Widget> get _pages {
    return [
      HomePage(
        onOpenProfile: () => _goToTab(_profileIndex),
      ),
      CoursesPage(
        onBackToHome: () => _goToTab(_homeIndex),
      ),
      LibraryPage(
        onBackToHome: () => _goToTab(_homeIndex),
      ),
      CommunityPage(
        onBackToHome: () => _goToTab(_homeIndex),
      ),
      ProfilePage(
        onBackToHome: () => _goToTab(_homeIndex),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: SafeArea(
          child: IndexedStack(
            index: _currentIndex,
            children: _pages,
          ),
        ),
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(
              top: BorderSide(color: AppColors.border),
            ),
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: _goToTab,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home_rounded),
                label: 'الرئيسية',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.menu_book_outlined),
                activeIcon: Icon(Icons.menu_book_rounded),
                label: 'دوراتي',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.local_library_outlined),
                activeIcon: Icon(Icons.local_library_rounded),
                label: 'المكتبة',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.groups_outlined),
                activeIcon: Icon(Icons.groups_rounded),
                label: 'المجتمع',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline_rounded),
                activeIcon: Icon(Icons.person_rounded),
                label: 'ملفي',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
