import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/models/monitored_app_model.dart';

class AppListTile extends StatelessWidget {
  final MonitoredAppModel app;
  final int todayUsageSeconds;
  final VoidCallback onSettingsTap;
  final ValueChanged<bool> onLockToggle;

  const AppListTile({
    super.key,
    required this.app,
    required this.todayUsageSeconds,
    required this.onSettingsTap,
    required this.onLockToggle,
  });

  String _formatDuration(int seconds) {
    if (seconds < 60) return '${seconds}s';
    final minutes = seconds ~/ 60;
    if (minutes < 60) return '${minutes}m';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return mins > 0 ? '${hours}h ${mins}m' : '${hours}h';
  }

  double get _usageProgress {
    if (app.dailyLimitMinutes == null || app.dailyLimitMinutes! <= 0) return 0.0;
    final limitSeconds = app.dailyLimitMinutes! * 60;
    return (todayUsageSeconds / limitSeconds).clamp(0.0, 1.0);
  }

  Color get _progressColor {
    if (_usageProgress >= 1.0) return AppColors.error;
    if (_usageProgress >= 0.8) return AppColors.warning;
    return AppColors.brandPrimary;
  }

  Color get _iconColor {
    final colors = [
      AppColors.brandPrimary,
      AppColors.brandSecondary,
      AppColors.brandAccent,
      AppColors.focusSession,
      AppColors.warning,
    ];
    final index = app.packageName.length % colors.length;
    return colors[index];
  }

  String get _appInitial {
    return app.appName.isNotEmpty ? app.appName[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(
          color: app.isLocked ? AppColors.brandPrimary.withOpacity(0.3) : AppColors.border,
        ),
      ),
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          children: [
            Row(
              children: [
                // App icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _iconColor.withOpacity(0.15),
                    borderRadius: AppSpacing.borderRadiusMd,
                    border: Border.all(color: _iconColor.withOpacity(0.3)),
                  ),
                  child: Center(
                    child: Text(
                      _appInitial,
                      style: AppTypography.h3.copyWith(color: _iconColor),
                    ),
                  ),
                ),
                AppSpacing.hGap(AppSpacing.md),
                // App info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              app.appName,
                              style: AppTypography.labelMedium,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (app.isLocked) ...[
                            AppSpacing.hGap(AppSpacing.xs),
                            _buildLockChip(),
                          ],
                        ],
                      ),
                      AppSpacing.vGap(2),
                      Text(
                        app.packageName,
                        style: AppTypography.caption,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Settings icon
                IconButton(
                  onPressed: onSettingsTap,
                  icon: const Icon(
                    Icons.tune_rounded,
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
              ],
            ),
            // Usage bar
            if (app.dailyLimitMinutes != null || todayUsageSeconds > 0) ...[
              AppSpacing.vGap(AppSpacing.md),
              _buildUsageRow(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLockChip() {
    final isStrict = app.lockMode == 'strict';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isStrict
            ? AppColors.error.withOpacity(0.15)
            : AppColors.brandPrimary.withOpacity(0.15),
        borderRadius: AppSpacing.borderRadiusFull,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isStrict ? Icons.lock : Icons.lock_open_rounded,
            size: 10,
            color: isStrict ? AppColors.error : AppColors.brandPrimary,
          ),
          const SizedBox(width: 3),
          Text(
            isStrict ? 'strict' : 'soft',
            style: AppTypography.caption.copyWith(
              color: isStrict ? AppColors.error : AppColors.brandPrimary,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsageRow() {
    final usageText = _formatDuration(todayUsageSeconds);
    final limitText = app.dailyLimitMinutes != null
        ? '${app.dailyLimitMinutes! >= 60 ? '${app.dailyLimitMinutes! ~/ 60}h ${app.dailyLimitMinutes! % 60 > 0 ? '${app.dailyLimitMinutes! % 60}m' : ''}' : '${app.dailyLimitMinutes}m'} limit'
        : 'No limit';

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Today: $usageText',
              style: AppTypography.caption,
            ),
            Text(
              limitText.trim(),
              style: AppTypography.caption.copyWith(
                color: app.dailyLimitMinutes != null
                    ? AppColors.textSecondary
                    : AppColors.textDisabled,
              ),
            ),
          ],
        ),
        if (app.dailyLimitMinutes != null) ...[
          AppSpacing.vGap(6),
          ClipRRect(
            borderRadius: AppSpacing.borderRadiusFull,
            child: LinearProgressIndicator(
              value: _usageProgress,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(_progressColor),
              minHeight: 4,
            ),
          ),
        ],
      ],
    );
  }
}
