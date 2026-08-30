import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    this.controller,
    this.hintText,
    this.labelText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.maxLines = 1,
    this.validator,
    this.onChanged,
    this.enabled = true,
  });

  final TextEditingController? controller;
  final String? hintText;
  final String? labelText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final int maxLines;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(18);

    final border = OutlineInputBorder(
      borderRadius: borderRadius,
      borderSide: const BorderSide(color: AppColors.border),
    );

    return TextFormField(
      controller: controller,
      enabled: enabled,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      maxLines: obscureText ? 1 : maxLines,
      validator: validator,
      onChanged: onChanged,
      textAlign: TextAlign.right,
      cursorColor: AppColors.primary,
      style: const TextStyle(
        color: AppColors.text,
        fontSize: 14,
        height: 1.35,
        fontWeight: FontWeight.w800,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: enabled ? AppColors.surfaceSoft : AppColors.surfaceMuted,
        hintText: hintText,
        labelText: labelText,
        hintTextDirection: TextDirection.rtl,
        alignLabelWithHint: maxLines > 1,
        prefixIcon: prefixIcon == null
            ? null
            : Icon(
                prefixIcon,
                color: enabled ? AppColors.primary : AppColors.textMuted,
                size: 22,
              ),
        suffixIcon: suffixIcon,
        hintStyle: const TextStyle(
          color: AppColors.textSoft,
          fontSize: 13,
          height: 1.35,
          fontWeight: FontWeight.w600,
        ),
        labelStyle: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
        floatingLabelStyle: const TextStyle(
          color: AppColors.primary,
          fontSize: 13,
          fontWeight: FontWeight.w800,
        ),
        errorStyle: const TextStyle(
          color: AppColors.danger,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 15,
        ),
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 1.35,
          ),
        ),
        errorBorder: border.copyWith(
          borderSide: const BorderSide(
            color: AppColors.danger,
            width: 1.2,
          ),
        ),
        focusedErrorBorder: border.copyWith(
          borderSide: const BorderSide(
            color: AppColors.danger,
            width: 1.35,
          ),
        ),
        disabledBorder: border.copyWith(
          borderSide: const BorderSide(color: AppColors.borderSoft),
        ),
      ),
    );
  }
}
