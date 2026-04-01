import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';

enum MlButtonVariant { primary, secondary, ghost, danger }
enum MlButtonSize { sm, md, lg }

class MlButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final MlButtonVariant variant;
  final MlButtonSize size;
  final bool isLoading;
  final bool fullWidth;
  final IconData? leadingIcon;
  final IconData? trailingIcon;

  const MlButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = MlButtonVariant.primary,
    this.size = MlButtonSize.md,
    this.isLoading = false,
    this.fullWidth = true,
    this.leadingIcon,
    this.trailingIcon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: fullWidth ? double.infinity : null,
      height: _height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: _buttonStyle,
        child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: _foregroundColor,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (leadingIcon != null) ...[
                    Icon(leadingIcon, size: _iconSize),
                    AppSpacing.hGap(AppSpacing.sm),
                  ],
                  Text(label, style: _textStyle),
                  if (trailingIcon != null) ...[
                    AppSpacing.hGap(AppSpacing.sm),
                    Icon(trailingIcon, size: _iconSize),
                  ],
                ],
              ),
      ),
    );
  }

  double get _height => switch (size) {
    MlButtonSize.sm => 40,
    MlButtonSize.md => 52,
    MlButtonSize.lg => 60,
  };

  double get _iconSize => switch (size) {
    MlButtonSize.sm => 16,
    MlButtonSize.md => 20,
    MlButtonSize.lg => 22,
  };

  Color get _backgroundColor => switch (variant) {
    MlButtonVariant.primary   => AppColors.brandPrimary,
    MlButtonVariant.secondary => AppColors.surfaceElevated,
    MlButtonVariant.ghost     => Colors.transparent,
    MlButtonVariant.danger    => AppColors.error,
  };

  Color get _foregroundColor => switch (variant) {
    MlButtonVariant.primary   => AppColors.textPrimary,
    MlButtonVariant.secondary => AppColors.textPrimary,
    MlButtonVariant.ghost     => AppColors.brandPrimary,
    MlButtonVariant.danger    => AppColors.textPrimary,
  };

  TextStyle get _textStyle => switch (size) {
    MlButtonSize.sm => AppTypography.labelMedium.copyWith(color: _foregroundColor),
    MlButtonSize.md => AppTypography.button.copyWith(color: _foregroundColor),
    MlButtonSize.lg => AppTypography.button.copyWith(color: _foregroundColor, fontSize: 18),
  };

  ButtonStyle get _buttonStyle => ElevatedButton.styleFrom(
    backgroundColor: _backgroundColor,
    foregroundColor: _foregroundColor,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: AppSpacing.borderRadiusMd,
      side: variant == MlButtonVariant.secondary
          ? const BorderSide(color: AppColors.border)
          : BorderSide.none,
    ),
    padding: EdgeInsets.symmetric(
      horizontal: size == MlButtonSize.sm ? 12 : 16,
    ),
  );
}
