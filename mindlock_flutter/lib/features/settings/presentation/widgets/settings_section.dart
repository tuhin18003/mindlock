import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';

class SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const SettingsSection({
    super.key,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.xxl,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          child: Text(
            title.toUpperCase(),
            style: AppTypography.overline.copyWith(color: AppColors.textTertiary),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(
              top: BorderSide(color: AppColors.border, width: 0.5),
              bottom: BorderSide(color: AppColors.border, width: 0.5),
            ),
          ),
          child: Column(
            children: [
              for (int i = 0; i < children.length; i++) ...[
                children[i],
                if (i < children.length - 1)
                  const Divider(
                    color: AppColors.borderSubtle,
                    height: 1,
                    indent: AppSpacing.lg,
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
