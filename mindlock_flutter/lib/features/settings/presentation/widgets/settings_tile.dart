import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';

class SettingsTile extends StatelessWidget {
  final IconData? icon;
  final Color? iconColor;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showArrow;

  const SettingsTile({
    super.key,
    this.icon,
    this.iconColor,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.showArrow = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      splashColor: AppColors.brandPrimary.withOpacity(0.08),
      highlightColor: AppColors.surfaceHighlight.withOpacity(0.5),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: (iconColor ?? AppColors.brandPrimary).withOpacity(0.12),
                  borderRadius: AppSpacing.borderRadiusSm,
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: iconColor ?? AppColors.brandPrimary,
                ),
              ),
              AppSpacing.hGap(AppSpacing.md),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: AppTypography.bodyLarge),
                  if (subtitle != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(subtitle!, style: AppTypography.bodySmall),
                    ),
                ],
              ),
            ),
            if (trailing != null) trailing!,
            if (showArrow && trailing == null)
              const Icon(
                Icons.chevron_right,
                color: AppColors.textTertiary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}

class SettingsSwitchTile extends StatelessWidget {
  final IconData? icon;
  final Color? iconColor;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const SettingsSwitchTile({
    super.key,
    this.icon,
    this.iconColor,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SettingsTile(
      icon: icon,
      iconColor: iconColor,
      title: title,
      subtitle: subtitle,
      onTap: () => onChanged(!value),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.brandPrimary,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}
