import 'package:flutter/material.dart';

class MenuItemModel {
  const MenuItemModel({
    required this.title,
    this.subtitle,
    this.icon,
    this.routeName,
    this.onTapKey,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final String? routeName;
  final String? onTapKey;

  bool get hasSubtitle {
    return subtitle != null && subtitle!.trim().isNotEmpty;
  }

  bool get hasRoute {
    return routeName != null && routeName!.trim().isNotEmpty;
  }

  bool get hasActionKey {
    return onTapKey != null && onTapKey!.trim().isNotEmpty;
  }

  MenuItemModel copyWith({
    String? title,
    String? subtitle,
    IconData? icon,
    String? routeName,
    String? onTapKey,
  }) {
    return MenuItemModel(
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      icon: icon ?? this.icon,
      routeName: routeName ?? this.routeName,
      onTapKey: onTapKey ?? this.onTapKey,
    );
  }
}
