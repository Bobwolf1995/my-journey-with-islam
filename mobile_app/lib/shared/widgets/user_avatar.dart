import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.size = 44,
    this.backgroundColor = AppColors.primary,
    this.foregroundColor = Colors.white,
  });

  final String name;
  final String? imageUrl;
  final double size;
  final Color backgroundColor;
  final Color foregroundColor;

  String get _initial {
    final trimmedName = name.trim();

    if (trimmedName.isEmpty) {
      return '؟';
    }

    return trimmedName.characters.first;
  }

  bool get _hasImage {
    return imageUrl != null && imageUrl!.trim().isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.035),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.surface,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.82),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: backgroundColor.withValues(alpha: 0.12),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: backgroundColor,
        ),
        child: _hasImage
            ? Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _InitialAvatar(
                    initial: _initial,
                    foregroundColor: foregroundColor,
                    fontSize: size * 0.38,
                  );
                },
              )
            : _InitialAvatar(
                initial: _initial,
                foregroundColor: foregroundColor,
                fontSize: size * 0.38,
              ),
      ),
    );
  }
}

class _InitialAvatar extends StatelessWidget {
  const _InitialAvatar({
    required this.initial,
    required this.foregroundColor,
    required this.fontSize,
  });

  final String initial;
  final Color foregroundColor;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        initial,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: foregroundColor,
          fontSize: fontSize,
          height: 1,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
