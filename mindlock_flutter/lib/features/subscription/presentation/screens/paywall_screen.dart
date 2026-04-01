import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../services/analytics/analytics_service.dart';

class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  int _selectedPlanIndex = 1; // default to annual

  @override
  void initState() {
    super.initState();
    ref.read(analyticsServiceProvider).track(AnalyticsEvent.paywallViewed);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: AppColors.black,
            pinned: true,
            elevation: 0,
            leading: IconButton(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.close),
            ),
            title: const Text('MindLock Pro', style: AppTypography.h3),
          ),
          SliverPadding(
            padding: AppSpacing.screenPaddingFull,
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildHeroSection(),
                AppSpacing.vGap(AppSpacing.xxl),
                _buildFeaturesList(),
                AppSpacing.vGap(AppSpacing.xxl),
                _buildPlanSelector(),
                AppSpacing.vGap(AppSpacing.xxl),
                _buildCTA(),
                AppSpacing.vGap(AppSpacing.lg),
                _buildRestoreAndTerms(),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection() {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            gradient: AppColors.brandGradient,
            borderRadius: AppSpacing.borderRadiusXl,
          ),
          child: const Icon(Icons.lock_open_outlined, color: Colors.white, size: 36),
        ),
        AppSpacing.vGap(AppSpacing.lg),
        Text(
          'Unlock Your Full Potential',
          style: AppTypography.h1,
          textAlign: TextAlign.center,
        ),
        AppSpacing.vGap(AppSpacing.sm),
        Text(
          'Join people who reclaim hours every day.',
          style: AppTypography.bodyMedium,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFeaturesList() {
    const features = [
      ('Unlimited app monitoring', Icons.all_inclusive, false),
      ('Advanced challenge library', Icons.extension_outlined, false),
      ('Strict mode — no emergency unlock', Icons.security_outlined, false),
      ('Detailed weekly analytics', Icons.bar_chart, false),
      ('Behavior insights + AI coaching', Icons.psychology_outlined, false),
      ('Mood & intent tracking', Icons.spa_outlined, false),
      ('Recovery mode', Icons.healing_outlined, false),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Everything in Pro', style: AppTypography.overline),
        AppSpacing.vGap(AppSpacing.md),
        ...features.map((f) => Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.brandPrimary.withOpacity(0.12),
                  borderRadius: AppSpacing.borderRadiusSm,
                ),
                child: Icon(f.$2, color: AppColors.brandPrimary, size: 16),
              ),
              AppSpacing.hGap(AppSpacing.md),
              Text(f.$1, style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary)),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildPlanSelector() {
    final plans = [
      _PlanOption(
        label: 'Monthly',
        price: '\$4.99',
        period: '/month',
        badge: null,
        index: 0,
      ),
      _PlanOption(
        label: 'Annual',
        price: '\$34.99',
        period: '/year',
        badge: 'BEST VALUE — Save 42%',
        index: 1,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Choose your plan', style: AppTypography.overline),
        AppSpacing.vGap(AppSpacing.md),
        ...plans.map((plan) => Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: _buildPlanTile(plan),
        )),
        AppSpacing.vGap(AppSpacing.sm),
        Center(
          child: Text(
            '7-day free trial included',
            style: AppTypography.bodySmall.copyWith(color: AppColors.brandSecondary),
          ),
        ),
      ],
    );
  }

  Widget _buildPlanTile(_PlanOption plan) {
    final isSelected = _selectedPlanIndex == plan.index;

    return GestureDetector(
      onTap: () => setState(() => _selectedPlanIndex = plan.index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: AppSpacing.cardPadding,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.brandPrimary.withOpacity(0.08) : AppColors.surfaceElevated,
          borderRadius: AppSpacing.borderRadiusLg,
          border: Border.all(
            color: isSelected ? AppColors.brandPrimary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.brandPrimary : AppColors.border,
                  width: 2,
                ),
                color: isSelected ? AppColors.brandPrimary : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 12)
                  : null,
            ),
            AppSpacing.hGap(AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(plan.label, style: AppTypography.labelLarge),
                      if (plan.badge != null) ...[
                        AppSpacing.hGap(AppSpacing.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            gradient: AppColors.brandGradient,
                            borderRadius: AppSpacing.borderRadiusFull,
                          ),
                          child: Text(
                            plan.badge!,
                            style: AppTypography.overline.copyWith(
                              color: Colors.white,
                              fontSize: 8,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(plan.price, style: AppTypography.labelLarge.copyWith(
                  color: isSelected ? AppColors.brandPrimary : AppColors.textPrimary,
                )),
                Text(plan.period, style: AppTypography.caption),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCTA() {
    return ElevatedButton(
      onPressed: _handleUpgrade,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: AppSpacing.borderRadiusMd),
        backgroundColor: AppColors.brandPrimary,
      ),
      child: Text(
        'Start 7-Day Free Trial',
        style: AppTypography.button,
      ),
    );
  }

  Widget _buildRestoreAndTerms() {
    return Column(
      children: [
        TextButton(
          onPressed: () {},
          child: const Text('Restore Purchases'),
        ),
        Text(
          'Cancel anytime. Billed after trial ends.',
          style: AppTypography.caption,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  void _handleUpgrade() {
    ref.read(analyticsServiceProvider).track(AnalyticsEvent.upgradeStarted, properties: {
      'plan_index': _selectedPlanIndex,
    });
    // TODO: Integrate Google Play / Apple billing in Phase 16
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Billing integration coming in production build')),
    );
  }
}

class _PlanOption {
  final String label;
  final String price;
  final String period;
  final String? badge;
  final int index;

  const _PlanOption({
    required this.label,
    required this.price,
    required this.period,
    required this.badge,
    required this.index,
  });
}
