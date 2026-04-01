import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';

class StreakBanner extends StatelessWidget {
  final int currentStreak;

  const StreakBanner({super.key, required this.currentStreak});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: currentStreak > 0 ? AppColors.proBadgeSurface : AppColors.surfaceElevated,
        borderRadius: AppSpacing.borderRadiusMd,
        border: Border.all(
          color: currentStreak > 0
              ? AppColors.proBadgeGold.withOpacity(0.4)
              : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Text(
            currentStreak > 0 ? '🔥' : '⬜',
            style: const TextStyle(fontSize: 20),
          ),
          AppSpacing.hGap(AppSpacing.xs),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                currentStreak > 0 ? '$currentStreak day streak' : 'No streak yet',
                style: AppTypography.labelMedium.copyWith(
                  color: currentStreak > 0 ? AppColors.proBadgeGold : AppColors.textSecondary,
                ),
              ),
              Text(
                currentStreak > 0 ? 'Keep going!' : 'Start today',
                style: AppTypography.caption,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
