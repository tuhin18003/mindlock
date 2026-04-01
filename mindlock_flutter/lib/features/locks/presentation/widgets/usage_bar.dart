import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

class UsageBar extends StatelessWidget {
  final int usedSeconds;
  final int limitSeconds;

  const UsageBar({
    super.key,
    required this.usedSeconds,
    required this.limitSeconds,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = limitSeconds > 0
        ? (usedSeconds / limitSeconds).clamp(0.0, 1.0)
        : 1.0;

    return Column(
      children: [
        ClipRRect(
          borderRadius: AppSpacing.borderRadiusFull,
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 8,
            backgroundColor: AppColors.surfaceHighlight,
            valueColor: AlwaysStoppedAnimation<Color>(
              ratio >= 1.0 ? AppColors.error : AppColors.brandPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
