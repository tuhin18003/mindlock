import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';

class LockAppHeader extends StatelessWidget {
  final String appName;
  final String packageName;
  final Animation<double> pulseAnimation;

  const LockAppHeader({
    super.key,
    required this.appName,
    required this.packageName,
    required this.pulseAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
      child: Column(
        children: [
          ScaleTransition(
            scale: pulseAnimation,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.surfaceHighlight,
                borderRadius: AppSpacing.borderRadiusXl,
                border: Border.all(color: AppColors.border, width: 2),
              ),
              child: const Icon(
                Icons.lock_outline,
                color: AppColors.brandPrimary,
                size: 40,
              ),
            ),
          ),
          AppSpacing.vGap(AppSpacing.lg),
          Text(appName, style: AppTypography.h2),
          AppSpacing.vGap(AppSpacing.xs),
          Text(
            'You\'ve reached your daily limit',
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textTertiary),
          ),
          AppSpacing.vGap(AppSpacing.xxl),
        ],
      ),
    );
  }
}
