import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../routes/app_routes.dart';
import '../../../../shared/widgets/pro_gate.dart';
import '../../../../services/entitlement/entitlement_service.dart';
import '../../data/models/analytics_models.dart';
import '../providers/analytics_provider.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(analyticsPeriodProvider);
    final analyticsAsync = ref.watch(analyticsProvider);
    final entitlement = ref.watch(entitlementServiceProvider);
    final isPro = entitlement.isPro;

    return Scaffold(
      backgroundColor: AppColors.black,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context, ref, period),
          SliverPadding(
            padding: AppSpacing.screenPadding,
            sliver: analyticsAsync.when(
              loading: () => SliverToBoxAdapter(
                child: _buildShimmer(),
              ),
              error: (e, _) => SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 60),
                  child: Center(
                    child: Text(
                      'Unable to load analytics',
                      style: AppTypography.bodyMedium,
                    ),
                  ),
                ),
              ),
              data: (summary) => _buildContent(context, ref, summary, isPro),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, WidgetRef ref, int period) {
    return SliverAppBar(
      backgroundColor: AppColors.black,
      floating: true,
      pinned: false,
      elevation: 0,
      title: Text('Analytics', style: AppTypography.h2),
      actions: [
        // Period selector
        Container(
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: AppSpacing.borderRadiusMd,
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildPeriodChip(ref, 7, period),
              _buildPeriodChip(ref, 30, period),
              _buildPeriodChip(ref, 90, period),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPeriodChip(WidgetRef ref, int days, int current) {
    final isSelected = days == current;
    return GestureDetector(
      onTap: () => ref.read(analyticsPeriodProvider.notifier).state = days,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.brandPrimary : Colors.transparent,
          borderRadius: AppSpacing.borderRadiusMd,
        ),
        child: Text(
          '${days}d',
          style: AppTypography.labelSmall.copyWith(
            color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    AnalyticsSummary summary,
    bool isPro,
  ) {
    return SliverList(
      delegate: SliverChildListDelegate([
        AppSpacing.vGap(AppSpacing.lg),
        // Key metrics row
        _buildMetricsRow(summary),
        AppSpacing.vGap(AppSpacing.xxl),

        // Screen time bar chart
        Text('SCREEN TIME', style: AppTypography.overline),
        AppSpacing.vGap(AppSpacing.md),
        _buildScreenTimeChart(summary),
        AppSpacing.vGap(AppSpacing.xxl),

        // Recovery score trend (Pro gate)
        Text('RECOVERY TREND', style: AppTypography.overline),
        AppSpacing.vGap(AppSpacing.md),
        ProGate(
          feature: MobileFeature.analyticsDetailed,
          upgradeLabel: 'Recovery Trend (Pro)',
          child: _buildRecoveryTrendChart(summary),
        ),
        AppSpacing.vGap(AppSpacing.xxl),

        // Top apps
        Text('TOP APPS BY SCREEN TIME', style: AppTypography.overline),
        AppSpacing.vGap(AppSpacing.md),
        _buildTopApps(summary),
        AppSpacing.vGap(AppSpacing.xxl),

        // Discipline metrics
        Text('DISCIPLINE METRICS', style: AppTypography.overline),
        AppSpacing.vGap(AppSpacing.md),
        _buildDisciplineMetrics(summary),
        AppSpacing.vGap(AppSpacing.xxl),

        // Upgrade banner for free users
        if (!isPro) ...[
          _buildUpgradeBanner(context),
          AppSpacing.vGap(AppSpacing.xxl),
        ],
      ]),
    );
  }

  Widget _buildMetricsRow(AnalyticsSummary summary) {
    String formatMinutes(double mins) {
      if (mins < 60) return '${mins.toInt()}m';
      final h = (mins / 60).floor();
      final m = (mins % 60).toInt();
      return m > 0 ? '${h}h ${m}m' : '${h}h';
    }

    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            'Avg Daily',
            formatMinutes(summary.avgDailyScreenMinutes),
            Icons.phone_android_outlined,
            AppColors.screenTime,
          ),
        ),
        AppSpacing.hGap(AppSpacing.md),
        Expanded(
          child: _buildMetricCard(
            'Total Locks',
            '${summary.totalLocks30d}',
            Icons.lock_outline_rounded,
            AppColors.brandPrimary,
          ),
        ),
        AppSpacing.hGap(AppSpacing.md),
        Expanded(
          child: _buildMetricCard(
            'Score',
            '${summary.recoveryScoreAvg}',
            Icons.bolt_rounded,
            AppColors.recoveredTime,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          AppSpacing.vGap(AppSpacing.sm),
          Text(value, style: AppTypography.statMedium.copyWith(fontSize: 22)),
          AppSpacing.vGap(2),
          Text(label, style: AppTypography.caption),
        ],
      ),
    );
  }

  Widget _buildScreenTimeChart(AnalyticsSummary summary) {
    if (summary.screenTimeTrend.isEmpty) {
      return _buildChartPlaceholder('No screen time data yet');
    }

    // Show last 7 days for bar chart
    final data = summary.screenTimeTrend.length > 7
        ? summary.screenTimeTrend.sublist(summary.screenTimeTrend.length - 7)
        : summary.screenTimeTrend;

    final maxY = data.fold<int>(0, (m, p) => p.screenMinutes > m ? p.screenMinutes : m);
    final chartMaxY = (maxY * 1.2).ceilToDouble();

    return Container(
      height: 200,
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(color: AppColors.border),
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: chartMaxY > 0 ? chartMaxY : 300,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final point = data[groupIndex];
                return BarTooltipItem(
                  '${point.screenMinutes}m\n',
                  AppTypography.labelSmall.copyWith(color: AppColors.textPrimary),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= data.length) return const SizedBox();
                  final date = data[index].date;
                  String label = date;
                  try {
                    final dt = DateTime.parse(date);
                    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                    label = days[dt.weekday - 1];
                  } catch (_) {}
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(label, style: AppTypography.caption),
                  );
                },
              ),
            ),
          ),
          gridData: FlGridData(
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(
              color: AppColors.border,
              strokeWidth: 0.5,
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: data.asMap().entries.map((entry) {
            final i = entry.key;
            final point = entry.value;
            final fraction = chartMaxY > 0 ? point.screenMinutes / chartMaxY : 0.0;
            final color = fraction >= 0.8
                ? AppColors.warning
                : fraction >= 0.6
                    ? AppColors.screenTime
                    : AppColors.brandPrimary;

            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: point.screenMinutes.toDouble(),
                  color: color,
                  width: 14,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: chartMaxY,
                    color: AppColors.border.withOpacity(0.3),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildRecoveryTrendChart(AnalyticsSummary summary) {
    if (summary.screenTimeTrend.isEmpty) {
      return _buildChartPlaceholder('No recovery data yet');
    }

    final data = summary.screenTimeTrend;
    final spots = data.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.recoveredMinutes.toDouble());
    }).toList();

    final maxY = data.fold<int>(0, (m, p) => p.recoveredMinutes > m ? p.recoveredMinutes : m);

    return Container(
      height: 160,
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(color: AppColors.border),
      ),
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: (maxY * 1.3).ceilToDouble(),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (spots) => spots.map((s) {
                return LineTooltipItem(
                  '${s.y.toInt()}m recovered',
                  AppTypography.caption.copyWith(color: AppColors.recoveredTime),
                );
              }).toList(),
            ),
          ),
          gridData: FlGridData(
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(
              color: AppColors.border,
              strokeWidth: 0.5,
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: AppColors.recoveredTime,
              barWidth: 2.5,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.recoveredTime.withOpacity(0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopApps(AnalyticsSummary summary) {
    if (summary.topApps.isEmpty) {
      return _buildChartPlaceholder('No app usage data yet');
    }

    final total = summary.topApps.fold<int>(0, (sum, a) => sum + a.totalMinutes);

    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: summary.topApps.asMap().entries.map((entry) {
          final i = entry.key;
          final app = entry.value;
          final fraction = total > 0 ? app.totalMinutes / total : 0.0;
          final percent = (fraction * 100).toStringAsFixed(0);
          final hours = app.totalMinutes ~/ 60;
          final mins = app.totalMinutes % 60;
          final timeStr = hours > 0 ? '${hours}h ${mins}m' : '${mins}m';

          final colors = [
            AppColors.brandPrimary,
            AppColors.brandSecondary,
            AppColors.brandAccent,
            AppColors.focusSession,
            AppColors.warning,
          ];
          final color = colors[i % colors.length];

          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        borderRadius: AppSpacing.borderRadiusSm,
                      ),
                      child: Center(
                        child: Text(
                          app.appName[0].toUpperCase(),
                          style: AppTypography.labelMedium.copyWith(color: color),
                        ),
                      ),
                    ),
                    AppSpacing.hGap(AppSpacing.md),
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
                              Text(timeStr, style: AppTypography.labelSmall),
                            ],
                          ),
                          AppSpacing.vGap(6),
                          Stack(
                            children: [
                              Container(
                                height: 4,
                                decoration: BoxDecoration(
                                  color: AppColors.border,
                                  borderRadius: AppSpacing.borderRadiusFull,
                                ),
                              ),
                              FractionallySizedBox(
                                widthFactor: fraction.clamp(0.0, 1.0),
                                child: Container(
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: color,
                                    borderRadius: AppSpacing.borderRadiusFull,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    AppSpacing.hGap(AppSpacing.md),
                    Text(
                      '$percent%',
                      style: AppTypography.caption.copyWith(color: color),
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDisciplineMetrics(AnalyticsSummary summary) {
    return Row(
      children: [
        Expanded(
          child: _buildRingCard(
            'Challenge\nSuccess',
            summary.challengeSuccessRate,
            AppColors.focusSession,
          ),
        ),
        AppSpacing.hGap(AppSpacing.md),
        Expanded(
          child: _buildRingCard(
            'Recovery\nScore',
            summary.recoveryScoreAvg,
            AppColors.recoveredTime,
          ),
        ),
        AppSpacing.hGap(AppSpacing.md),
        Expanded(
          child: _buildRingCard(
            'Lock\nDiscipline',
            (summary.totalLocks30d / 50 * 100).clamp(0, 100).toInt(),
            AppColors.brandPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildRingCard(String label, int percent, Color color) {
    final fraction = (percent / 100).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: fraction,
                  strokeWidth: 6,
                  backgroundColor: AppColors.border,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  strokeCap: StrokeCap.round,
                ),
                Center(
                  child: Text(
                    '$percent%',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textPrimary,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          AppSpacing.vGap(AppSpacing.sm),
          Text(
            label,
            style: AppTypography.caption,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildUpgradeBanner(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(AppRoutes.paywall),
      child: Container(
        padding: AppSpacing.cardPadding,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2D2060), Color(0xFF1A1040)],
          ),
          borderRadius: AppSpacing.borderRadiusLg,
          border: Border.all(color: AppColors.brandPrimary.withOpacity(0.4)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.brandPrimary.withOpacity(0.2),
                borderRadius: AppSpacing.borderRadiusFull,
              ),
              child: const Icon(
                Icons.auto_graph_rounded,
                color: AppColors.brandPrimary,
                size: 22,
              ),
            ),
            AppSpacing.hGap(AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Unlock Full Analytics History',
                    style: AppTypography.labelLarge.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  AppSpacing.vGap(2),
                  Text(
                    'Upgrade to Pro for 90-day trends, export reports, and deep insights.',
                    style: AppTypography.bodySmall,
                  ),
                ],
              ),
            ),
            AppSpacing.hGap(AppSpacing.sm),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.brandPrimary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartPlaceholder(String message) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(color: AppColors.border),
      ),
      child: Center(
        child: Text(message, style: AppTypography.bodyMedium),
      ),
    );
  }

  Widget _buildShimmer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSpacing.vGap(AppSpacing.lg),
        // Metrics row shimmer
        Row(
          children: List.generate(3, (_) => Expanded(
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              height: 90,
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: AppSpacing.borderRadiusLg,
              ),
            ),
          )),
        ),
        AppSpacing.vGap(AppSpacing.xl),
        // Chart shimmer
        Container(
          height: 200,
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: AppSpacing.borderRadiusLg,
          ),
        ),
        AppSpacing.vGap(AppSpacing.xl),
        Container(
          height: 160,
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: AppSpacing.borderRadiusLg,
          ),
        ),
        AppSpacing.vGap(AppSpacing.xl),
        // Top apps shimmer
        Container(
          height: 280,
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: AppSpacing.borderRadiusLg,
          ),
        ),
      ],
    );
  }
}
