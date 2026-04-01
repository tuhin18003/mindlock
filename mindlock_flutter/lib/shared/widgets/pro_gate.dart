import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import '../../routes/app_routes.dart';
import '../../services/entitlement/entitlement_service.dart';

/// Wraps any widget with a Pro gate.
/// If user is not Pro, shows a lock overlay instead.
class ProGate extends ConsumerWidget {
  final MobileFeature feature;
  final Widget child;
  final String? upgradeLabel;
  final bool showLockOverlay;

  const ProGate({
    super.key,
    required this.feature,
    required this.child,
    this.upgradeLabel,
    this.showLockOverlay = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entitlementService = ref.watch(entitlementServiceProvider);
    final canAccess = entitlementService.canAccess(feature);

    if (canAccess) return child;
    if (!showLockOverlay) return const SizedBox.shrink();

    return Stack(
      children: [
        Opacity(opacity: 0.3, child: child),
        Positioned.fill(
          child: GestureDetector(
            onTap: () => context.push(AppRoutes.paywall),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.black.withOpacity(0.7),
                borderRadius: AppSpacing.borderRadiusLg,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.proBadgeSurface,
                      borderRadius: AppSpacing.borderRadiusFull,
                      border: Border.all(color: AppColors.proBadgeGold.withOpacity(0.3)),
                    ),
                    child: const Icon(Icons.lock, color: AppColors.proBadgeGold, size: 20),
                  ),
                  AppSpacing.vGap(AppSpacing.sm),
                  Text(
                    upgradeLabel ?? 'Pro Feature',
                    style: AppTypography.labelMedium.copyWith(color: AppColors.proBadgeGold),
                  ),
                  Text('Tap to upgrade', style: AppTypography.caption),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
