import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/models/history_models.dart';

class ActivityEventTile extends StatelessWidget {
  final ActivityEvent event;

  const ActivityEventTile({super.key, required this.event});

  Color get _borderColor {
    switch (event.eventType) {
      case 'lock':
        return AppColors.brandPrimary;
      case 'unlock':
        return AppColors.brandSecondary;
      case 'challenge':
        return event.result == 'passed' ? AppColors.success : AppColors.warning;
      case 'focus':
        return AppColors.focusSession;
      case 'emergency':
        return AppColors.emergencyUnlock;
      default:
        return AppColors.border;
    }
  }

  Color get _iconBgColor => _borderColor.withOpacity(0.15);

  IconData get _icon {
    switch (event.eventType) {
      case 'lock':
        return Icons.lock_outline_rounded;
      case 'unlock':
        return Icons.lock_open_rounded;
      case 'challenge':
        return event.result == 'passed'
            ? Icons.emoji_events_outlined
            : Icons.replay_outlined;
      case 'focus':
        return Icons.timer_outlined;
      case 'emergency':
        return Icons.warning_amber_rounded;
      default:
        return Icons.circle_outlined;
    }
  }

  String get _description {
    switch (event.eventType) {
      case 'lock':
        final name = event.appName ?? event.packageName ?? 'App';
        return '$name locked';
      case 'unlock':
        final name = event.appName ?? event.packageName ?? 'App';
        final method = event.method ?? 'manual';
        final reward = event.rewardMinutes;
        return 'Unlocked $name via $method${reward != null ? ' (+${reward}m)' : ''}';
      case 'challenge':
        final result = event.result ?? 'unknown';
        final label = result == 'passed' ? 'Passed' : 'Failed';
        return '$label challenge';
      case 'focus':
        final mins = event.rewardMinutes ?? 0;
        return 'Focus session (${mins}m)';
      case 'emergency':
        final pkg = event.packageName ?? 'unknown app';
        return 'Emergency unlock — $pkg';
      default:
        return 'Activity';
    }
  }

  String _formatTime(String isoString) {
    try {
      final dt = DateTime.parse(isoString).toLocal();
      final hour = dt.hour;
      final minute = dt.minute.toString().padLeft(2, '0');
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      return '$displayHour:$minute $period';
    } catch (_) {
      return isoString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: AppSpacing.borderRadiusMd,
        border: Border(
          left: BorderSide(color: _borderColor, width: 3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            // Icon
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _iconBgColor,
                borderRadius: AppSpacing.borderRadiusSm,
              ),
              child: Icon(_icon, color: _borderColor, size: 18),
            ),
            AppSpacing.hGap(AppSpacing.md),
            // Description
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _description,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (event.eventType == 'unlock' && event.rewardMinutes != null) ...[
                    AppSpacing.vGap(2),
                    Text(
                      '+${event.rewardMinutes}m recovered',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.recoveredTime,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            AppSpacing.hGap(AppSpacing.sm),
            // Time
            Text(
              _formatTime(event.occurredAt),
              style: AppTypography.caption,
            ),
          ],
        ),
      ),
    );
  }
}
