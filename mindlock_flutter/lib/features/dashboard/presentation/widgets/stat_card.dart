import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';

class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;
  final VoidCallback? onTap;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
    this.onTap,
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: AppSpacing.borderRadiusSm,
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                if (onTap != null)
                  const Icon(Icons.arrow_forward_ios, size: 12, color: AppColors.textTertiary),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: AppTypography.statMedium.copyWith(fontSize: 22)),
                AppSpacing.vGap(AppSpacing.xs),
                Text(label, style: AppTypography.labelSmall),
                if (subtitle != null) ...[
                  AppSpacing.vGap(AppSpacing.xs),
                  Text(subtitle!, style: AppTypography.caption.copyWith(color: color)),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
