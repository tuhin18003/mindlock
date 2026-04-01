import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';
import '../providers/lock_screen_provider.dart';

class UnlockMethodCard extends StatelessWidget {
  final UnlockMethod method;
  final VoidCallback onTap;

  const UnlockMethodCard({
    super.key,
    required this.method,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: AppSpacing.cardPadding,
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: AppSpacing.borderRadiusLg,
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _iconBg,
                borderRadius: AppSpacing.borderRadiusMd,
              ),
              child: Icon(_icon, color: _iconColor, size: 22),
            ),
            AppSpacing.hGap(AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(method.title, style: AppTypography.labelMedium),
                      if (method.isPro) ...[
                        AppSpacing.hGap(AppSpacing.xs),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.proBadgeSurface,
                            borderRadius: AppSpacing.borderRadiusFull,
                            border: Border.all(color: AppColors.proBadgeGold.withOpacity(0.3)),
                          ),
                          child: Text('PRO', style: AppTypography.overline.copyWith(
                            color: AppColors.proBadgeGold,
                            fontSize: 9,
                          )),
                        ),
                      ],
                    ],
                  ),
                  AppSpacing.vGap(AppSpacing.xs),
                  Text(method.description, style: AppTypography.bodySmall),
                ],
              ),
            ),
            AppSpacing.hGap(AppSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '+${method.rewardMinutes}m',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.recoveredTime,
                  ),
                ),
                Text('reward', style: AppTypography.caption),
              ],
            ),
            AppSpacing.hGap(AppSpacing.xs),
            const Icon(Icons.chevron_right, color: AppColors.textTertiary, size: 18),
          ],
        ),
      ),
    );
  }

  IconData get _icon => switch (method.type) {
    UnlockMethodType.reflection => Icons.psychology_outlined,
    UnlockMethodType.learningTask => Icons.menu_book_outlined,
    UnlockMethodType.miniChallenge => Icons.emoji_events_outlined,
    UnlockMethodType.challenge => Icons.extension_outlined,
    UnlockMethodType.focusTimer => Icons.timer_outlined,
    UnlockMethodType.habitTask => Icons.check_circle_outline,
    UnlockMethodType.delayTimer => Icons.hourglass_empty,
  };

  Color get _iconColor => switch (method.type) {
    UnlockMethodType.reflection => AppColors.brandSecondary,
    UnlockMethodType.learningTask => AppColors.brandPrimary,
    UnlockMethodType.miniChallenge => AppColors.streak,
    UnlockMethodType.challenge => AppColors.brandPrimary,
    UnlockMethodType.focusTimer => AppColors.focusSession,
    UnlockMethodType.habitTask => AppColors.recoveredTime,
    UnlockMethodType.delayTimer => AppColors.textSecondary,
  };

  Color get _iconBg => _iconColor.withOpacity(0.1);
}
