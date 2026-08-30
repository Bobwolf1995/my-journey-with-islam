import 'package:flutter/material.dart';

import '../../shared/theme/app_colors.dart';

class Helpers {
  const Helpers._();

  static void hideKeyboard(BuildContext context) {
    FocusScope.of(context).unfocus();
  }

  static void showSuccessSnackBar(
    BuildContext context, {
    required String message,
  }) {
    showSnackBar(
      context,
      message: message,
      backgroundColor: AppColors.primary,
    );
  }

  static void showErrorSnackBar(
    BuildContext context, {
    required String message,
  }) {
    showSnackBar(
      context,
      message: message,
      backgroundColor: AppColors.danger,
    );
  }

  static void showSnackBar(
    BuildContext context, {
    required String message,
    Color backgroundColor = AppColors.primary,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          textAlign: TextAlign.right,
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: backgroundColor,
      ),
    );
  }

  static int asInt(
    dynamic value, {
    int fallback = 0,
  }) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    if (value is String) {
      return int.tryParse(value.trim()) ?? fallback;
    }

    return fallback;
  }

  static double asDouble(
    dynamic value, {
    double fallback = 0,
  }) {
    if (value is double) {
      return value;
    }

    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value.trim()) ?? fallback;
    }

    return fallback;
  }

  static String asString(
    dynamic value, {
    String fallback = '',
  }) {
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }

    if (value is num || value is bool) {
      return value.toString();
    }

    return fallback;
  }

  static bool asBool(
    dynamic value, {
    bool fallback = false,
  }) {
    if (value is bool) {
      return value;
    }

    if (value is num) {
      return value != 0;
    }

    if (value is String) {
      final normalized = value.trim().toLowerCase();

      if (normalized == 'true' || normalized == '1' || normalized == 'yes') {
        return true;
      }

      if (normalized == 'false' || normalized == '0' || normalized == 'no') {
        return false;
      }
    }

    return fallback;
  }
}
