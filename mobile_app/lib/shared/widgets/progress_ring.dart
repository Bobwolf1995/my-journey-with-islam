import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.progress,
    this.size = 92,
    this.strokeWidth = 8,
    this.label,
    this.center,
    this.color = AppColors.primary,
    this.backgroundColor = AppColors.surfaceMuted,
  });

  final double progress;
  final double size;
  final double strokeWidth;
  final String? label;
  final Widget? center;
  final Color color;
  final Color backgroundColor;

  double get _normalizedProgress {
    if (progress.isNaN || progress.isInfinite) {
      return 0;
    }

    if (progress < 0) {
      return 0;
    }

    if (progress > 1) {
      return 1;
    }

    return progress;
  }

  @override
  Widget build(BuildContext context) {
    final value = _normalizedProgress;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surface,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.10),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
          ),
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: value,
              strokeWidth: strokeWidth,
              backgroundColor: backgroundColor,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              strokeCap: StrokeCap.round,
            ),
          ),
          center ??
              Text(
                label ?? '${(value * 100).round()}%',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 18,
                  height: 1.1,
                  fontWeight: FontWeight.w900,
                ),
              ),
        ],
      ),
    );
  }
}
