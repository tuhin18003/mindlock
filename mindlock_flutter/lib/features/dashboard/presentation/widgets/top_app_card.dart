import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/date_utils.dart';

class TopAppCard extends StatelessWidget {
  final String packageName;
  final int usageSeconds;

  const TopAppCard({
    super.key,
    required this.packageName,
    required this.usageSeconds,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.surfaceHighlight,
              borderRadius: AppSpacing.borderRadiusMd,
            ),
            child: const Icon(Icons.apps, color: AppColors.textTertiary, size: 24),
          ),
          AppSpacing.hGap(AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_appName(packageName), style: AppTypography.labelMedium),
                AppSpacing.vGap(AppSpacing.xs),
                Text(
                  MindLockDateUtils.formatDurationSeconds(usageSeconds),
                  style: AppTypography.bodySmall.copyWith(color: AppColors.screenTime),
                ),
              ],
            ),
          ),
          Text(
            'Most used',
            style: AppTypography.caption.copyWith(color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }

  String _appName(String pkg) {
    const names = {
      'com.instagram.android': 'Instagram',
      'com.zhiliaoapp.musically': 'TikTok',
      'com.twitter.android': 'X (Twitter)',
      'com.facebook.katana': 'Facebook',
      'com.reddit.frontpage': 'Reddit',
    };
    return names[pkg] ?? pkg.split('.').last;
  }
}
