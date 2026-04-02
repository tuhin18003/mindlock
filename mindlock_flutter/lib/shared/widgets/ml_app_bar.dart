import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';

/// A reusable [SliverAppBar] with optional subtitle and actions.
class MLAppBar extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final Color backgroundColor;
  final bool floating;
  final bool pinned;
  final Widget? leading;

  const MLAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.backgroundColor = AppColors.black,
    this.floating = true,
    this.pinned = false,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      backgroundColor: backgroundColor,
      floating: floating,
      pinned: pinned,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: leading,
      automaticallyImplyLeading: leading != null,
      title: subtitle != null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(subtitle!, style: AppTypography.bodySmall),
                Text(title, style: AppTypography.h2),
              ],
            )
          : Text(title, style: AppTypography.h2),
      titleSpacing: leading != null ? null : AppSpacing.lg,
      actions: actions != null
          ? [
              ...actions!,
              AppSpacing.hGap(AppSpacing.sm),
            ]
          : null,
    );
  }
}
