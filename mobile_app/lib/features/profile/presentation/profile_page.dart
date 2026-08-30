import 'package:flutter/material.dart';

import '../../../shared/theme/app_colors.dart';
import '../../auth/data/current_user.dart';
import '../../auth/presentation/logout_button.dart';
import '../../badges/presentation/badges_page.dart';
import '../../chat/presentation/conversations_screen.dart';
import '../../journey/journey_screen.dart';
import '../../notifications/presentation/notifications_page.dart';
import '../data/profile_service.dart';
import '../settings_screen.dart';
import 'edit_profile_page.dart';
import 'favorites_screen.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({
    super.key,
    this.onBackToHome,
  });

  final VoidCallback? onBackToHome;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final ProfileService _profileService = ProfileService();

  late Future<CurrentUser> _currentUserFuture;

  @override
  void initState() {
    super.initState();
    _currentUserFuture = _profileService.getProfile();
  }

  Future<void> _refreshProfile() async {
    setState(() {
      _currentUserFuture = _profileService.getProfile();
    });

    await _currentUserFuture;
  }

  Future<void> _openEditProfile(CurrentUser user) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => EditProfilePage(user: user),
      ),
    );

    if (!mounted) {
      return;
    }

    if (result == true) {
      await _refreshProfile();
    }
  }

  Future<void> _openNotifications() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const NotificationsPage(),
      ),
    );

    if (!mounted) {
      return;
    }

    await _refreshProfile();
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const SettingsScreen(),
      ),
    );
  }

  void _openSupport() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const ConversationsScreen(),
      ),
    );
  }

  void _openJourney() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const JourneyScreen(),
      ),
    );
  }

  void _openFavorites() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const FavoritesScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: FutureBuilder<CurrentUser>(
        future: _currentUserFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const _ProfileLoading();
          }

          final user = snapshot.data ?? CurrentUser.fallback();

          return RefreshIndicator(
            color: AppColors.primary,
            backgroundColor: AppColors.surface,
            onRefresh: _refreshProfile,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
              child: Column(
                children: [
                  _ProfileHeader(
                    onSettings: _openSettings,
                    onBackToHome: widget.onBackToHome,
                  ),
                  const SizedBox(height: 18),
                  if (snapshot.hasError) ...[
                    const _ProfileNotice(),
                    const SizedBox(height: 14),
                  ],
                  _ProfileSummary(user: user),
                  const SizedBox(height: 14),
                  _StatsRow(user: user),
                  const SizedBox(height: 18),
                  _SettingsCard(
                    onJourney: _openJourney,
                    onFavorites: _openFavorites,
                    onEditProfile: () => _openEditProfile(user),
                    onSettings: _openSettings,
                    onNotifications: () {
                      _openNotifications();
                    },
                    onSupport: _openSupport,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ProfileLoading extends StatelessWidget {
  const _ProfileLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(
        color: AppColors.primary,
        strokeWidth: 2.6,
      ),
    );
  }
}

class _ProfileNotice extends StatelessWidget {
  const _ProfileNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.warning.withValues(alpha: 0.25),
        ),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: AppColors.warning,
            size: 20,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'تعذر تحديث بيانات الملف الشخصي الآن، يتم عرض آخر بيانات متاحة.',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: AppColors.text,
                fontSize: 13,
                height: 1.45,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.onSettings,
    this.onBackToHome,
  });

  final VoidCallback onSettings;
  final VoidCallback? onBackToHome;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _CircleButton(
          icon: Icons.settings_outlined,
          onTap: onSettings,
        ),
        const Spacer(),
        const Column(
          children: [
            Text(
              'ملفي الشخصي',
              style: TextStyle(
                color: AppColors.text,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: 3),
            Text(
              'بياناتك وتقدمك',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const Spacer(),
        _CircleButton(
          icon: Icons.arrow_back_ios_new_rounded,
          onTap: onBackToHome ?? () => Navigator.maybePop(context),
        ),
      ],
    );
  }
}

class _ProfileSummary extends StatelessWidget {
  const _ProfileSummary({
    required this.user,
  });

  final CurrentUser user;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.borderSoft),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 18,
            offset: Offset(0, 9),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [
                  AppColors.primary,
                  AppColors.primaryDark,
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.18),
                  blurRadius: 18,
                  offset: const Offset(0, 9),
                ),
              ],
            ),
            child: const Icon(
              Icons.person_rounded,
              color: Colors.white,
              size: 50,
            ),
          ),
          const SizedBox(height: 13),
          Text(
            user.name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            user.role,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          _LevelBadge(level: user.level),
        ],
      ),
    );
  }
}

class _LevelBadge extends StatelessWidget {
  const _LevelBadge({
    required this.level,
  });

  final String level;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Text(
        level,
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.user,
  });

  final CurrentUser user;

  void _openBadges(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const BadgesPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatTile(
            icon: Icons.workspace_premium_rounded,
            value: user.points.toString(),
            label: 'نقطة',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatTile(
            icon: Icons.emoji_events_rounded,
            value: user.badgesCount.toString(),
            label: 'أوسمة',
            onTap: _openBadges,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatTile(
            icon: Icons.menu_book_rounded,
            value: user.lessonsCount.toString(),
            label: 'دروس',
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.value,
    required this.label,
    this.onTap,
  });

  final IconData icon;
  final String value;
  final String label;
  final void Function(BuildContext context)? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      height: 122,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderSoft),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppColors.primary, size: 22),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) {
      return content;
    }

    return InkWell(
      onTap: () => onTap!(context),
      borderRadius: BorderRadius.circular(20),
      child: content,
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.onJourney,
    required this.onFavorites,
    required this.onEditProfile,
    required this.onSettings,
    required this.onNotifications,
    required this.onSupport,
  });

  final VoidCallback onJourney;
  final VoidCallback onFavorites;
  final VoidCallback onEditProfile;
  final VoidCallback onSettings;
  final VoidCallback onNotifications;
  final VoidCallback onSupport;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderSoft),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 18,
            offset: Offset(0, 9),
          ),
        ],
      ),
      child: Column(
        children: [
          _SettingsTile(
            icon: Icons.person_outline_rounded,
            title: 'رحلتي',
            onTap: onJourney,
          ),
          _SettingsTile(
            icon: Icons.favorite_border_rounded,
            title: 'مفضلاتي',
            onTap: onFavorites,
          ),
          _SettingsTile(
            icon: Icons.edit_outlined,
            title: 'تعديل الملف الشخصي',
            onTap: onEditProfile,
          ),
          _SettingsTile(
            icon: Icons.settings_outlined,
            title: 'إعدادات الحساب',
            onTap: onSettings,
          ),
          _SettingsTile(
            icon: Icons.notifications_none_rounded,
            title: 'التنبيهات',
            onTap: onNotifications,
          ),
          _SettingsTile(
            icon: Icons.help_outline_rounded,
            title: 'مساعدة والدعم',
            onTap: onSupport,
          ),
          const Padding(
            padding: EdgeInsets.all(12),
            child: LogoutButton(),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.borderSoft),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.surfaceSoft,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderSoft),
            ),
            child: const Icon(
              Icons.chevron_left_rounded,
              color: AppColors.textMuted,
              size: 22,
            ),
          ),
          const Spacer(),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppColors.primary, size: 21),
          ),
        ],
      ),
    );

    if (onTap == null) {
      return content;
    }

    return InkWell(
      onTap: onTap,
      child: content,
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(17),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: AppColors.borderSoft),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 16,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Icon(icon, color: AppColors.text, size: 20),
      ),
    );
  }
}
