import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../routes/app_routes.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/stat_card.dart';
import '../widgets/recovery_score_ring.dart';
import '../widgets/streak_banner.dart';
import '../widgets/top_app_card.dart';
import '../widgets/weekly_trend_chart.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(dashboardSummaryProvider);

    return Scaffold(
      backgroundColor: AppColors.black,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context),
          SliverPadding(
            padding: AppSpacing.screenPadding,
            sliver: dashboardAsync.when(
              loading: () => const SliverToBoxAdapter(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => SliverToBoxAdapter(
                child: Center(child: Text('Error loading dashboard: $e')),
              ),
              data: (summary) => _buildDashboardContent(context, ref, summary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      backgroundColor: AppColors.black,
      floating: true,
      pinned: false,
      elevation: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            MindLockDateUtils.formatDate(DateTime.now()),
            style: AppTypography.bodySmall,
          ),
          Text('MindLock', style: AppTypography.h2),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.notifications_outlined),
        ),
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.account_circle_outlined),
        ),
      ],
    );
  }

  Widget _buildDashboardContent(
    BuildContext context,
    WidgetRef ref,
    DashboardSummary summary,
  ) {
    return SliverList(
      delegate: SliverChildListDelegate([
        // Recovery score ring + streak
        Row(
          children: [
            Expanded(
              flex: 2,
              child: RecoveryScoreRing(score: summary.recoveryScore),
            ),
            AppSpacing.hGap(AppSpacing.md),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StreakBanner(currentStreak: summary.currentStreak),
                  AppSpacing.vGap(AppSpacing.sm),
                  _buildInsightCard(summary),
                ],
              ),
            ),
          ],
        ),

        AppSpacing.vGap(AppSpacing.xxl),

        // Key stats grid
        Text('Today', style: AppTypography.overline),
        AppSpacing.vGap(AppSpacing.md),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: AppSpacing.md,
          mainAxisSpacing: AppSpacing.md,
          childAspectRatio: 1.4,
          children: [
            StatCard(
              label: 'Screen Time',
              value: MindLockDateUtils.formatDurationSeconds(summary.screenTimeSeconds),
              icon: Icons.phone_android,
              color: AppColors.screenTime,
            ),
            StatCard(
              label: 'Recovered',
              value: MindLockDateUtils.formatMinutes(summary.recoveredMinutes),
              icon: Icons.bolt,
              color: AppColors.recoveredTime,
            ),
            StatCard(
              label: 'Locks',
              value: '${summary.lockCount}',
              icon: Icons.lock_outline,
              color: AppColors.blockedTime,
            ),
            StatCard(
              label: 'Focus',
              value: MindLockDateUtils.formatMinutes(summary.focusMinutes),
              icon: Icons.timer_outlined,
              color: AppColors.focusSession,
            ),
          ],
        ),

        AppSpacing.vGap(AppSpacing.xxl),

        // Top distraction app
        if (summary.topDistractionApp != null) ...[
          Text('Top Distraction', style: AppTypography.overline),
          AppSpacing.vGap(AppSpacing.md),
          TopAppCard(
            packageName: summary.topDistractionApp!,
            usageSeconds: summary.topDistractionSeconds,
          ),
          AppSpacing.vGap(AppSpacing.xxl),
        ],

        // Weekly trend
        Text('This Week', style: AppTypography.overline),
        AppSpacing.vGap(AppSpacing.md),
        WeeklyTrendChart(
          weeklyData: summary.weeklyTrend,
          isProUser: summary.isProUser,
          onUpgradeTap: () => context.push(AppRoutes.paywall),
        ),

        AppSpacing.vGap(AppSpacing.xxl),

        // Challenges today
        if (summary.challengeCompletionsToday > 0) ...[
          _buildChallengeCompletionBanner(summary.challengeCompletionsToday),
          AppSpacing.vGap(AppSpacing.xxl),
        ],

        // Emergency unlock warning
        if (summary.emergencyUnlocksToday > 0) ...[
          _buildEmergencyAlert(summary.emergencyUnlocksToday),
          AppSpacing.vGap(AppSpacing.xxl),
        ],
      ]),
    );
  }

  Widget _buildInsightCard(DashboardSummary summary) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: AppSpacing.borderRadiusMd,
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        summary.behaviorInsight ?? 'Keep building your discipline.',
        style: AppTypography.bodySmall,
      ),
    );
  }

  Widget _buildChallengeCompletionBanner(int count) {
    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        gradient: AppColors.recoveryGradient,
        borderRadius: AppSpacing.borderRadiusLg,
      ),
      child: Row(
        children: [
          const Icon(Icons.emoji_events, color: Colors.white, size: 28),
          AppSpacing.hGap(AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count challenge${count > 1 ? 's' : ''} completed today',
                  style: AppTypography.labelLarge.copyWith(color: Colors.white),
                ),
                Text(
                  'Your discipline is building.',
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyAlert(int count) {
    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.warningSurface,
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(color: AppColors.warning.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber, color: AppColors.warning, size: 22),
          AppSpacing.hGap(AppSpacing.md),
          Expanded(
            child: Text(
              '$count emergency unlock${count > 1 ? 's' : ''} used today.',
              style: AppTypography.bodyMedium.copyWith(color: AppColors.warning),
            ),
          ),
        ],
      ),
    );
  }
}
