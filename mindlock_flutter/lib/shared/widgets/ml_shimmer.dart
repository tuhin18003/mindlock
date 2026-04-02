import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// A single shimmer placeholder block.
class MLShimmer extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const MLShimmer({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.borderRadius = AppSpacing.radiusSm,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surfaceElevated,
      highlightColor: AppColors.border,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

/// A column of shimmer tile placeholders for list loading states.
class MLShimmerList extends StatelessWidget {
  final int itemCount;
  final double itemHeight;
  final double spacing;

  const MLShimmerList({
    super.key,
    this.itemCount = 5,
    this.itemHeight = 64,
    this.spacing = AppSpacing.sm,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(itemCount, (i) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: i < itemCount - 1 ? spacing : 0,
          ),
          child: _ShimmerListItem(height: itemHeight),
        );
      }),
    );
  }
}

class _ShimmerListItem extends StatelessWidget {
  final double height;

  const _ShimmerListItem({required this.height});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surfaceElevated,
      highlightColor: AppColors.border,
      child: Container(
        height: height,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: AppSpacing.borderRadiusMd,
        ),
        child: Row(
          children: [
            // Avatar/icon placeholder
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: AppSpacing.borderRadiusSm,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            // Text placeholders
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 14,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 11,
                    width: 120,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
