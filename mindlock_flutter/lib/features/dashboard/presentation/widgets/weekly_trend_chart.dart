import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';
import '../providers/dashboard_provider.dart';

class WeeklyTrendChart extends StatelessWidget {
  final List<WeeklyDataPoint> weeklyData;
  final bool isProUser;
  final VoidCallback onUpgradeTap;

  const WeeklyTrendChart({
    super.key,
    required this.weeklyData,
    required this.isProUser,
    required this.onUpgradeTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(color: AppColors.border),
      ),
      child: isProUser
          ? _buildChart()
          : _buildUpgradeOverlay(context),
    );
  }

  Widget _buildChart() {
    return BarChart(
      BarChartData(
        backgroundColor: Colors.transparent,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                final idx = value.toInt();
                return Text(
                  days[idx % 7],
                  style: AppTypography.caption,
                );
              },
              reservedSize: 20,
            ),
          ),
        ),
        barGroups: List.generate(weeklyData.length, (i) {
          final point = weeklyData[i];
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: point.screenSeconds / 3600.0,
                color: AppColors.screenTime.withOpacity(0.6),
                width: 16,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildUpgradeOverlay(BuildContext context) {
    return ClipRRect(
      borderRadius: AppSpacing.borderRadiusMd,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Opacity(opacity: 0.2, child: _buildChart()),
          Container(
            padding: AppSpacing.cardPadding,
            decoration: BoxDecoration(
              color: AppColors.surfaceHighlight.withOpacity(0.9),
              borderRadius: AppSpacing.borderRadiusMd,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.bar_chart, color: AppColors.brandPrimary, size: 28),
                AppSpacing.vGap(AppSpacing.xs),
                Text('Weekly trends', style: AppTypography.labelMedium),
                Text('Upgrade to Pro', style: AppTypography.bodySmall),
                AppSpacing.vGap(AppSpacing.sm),
                TextButton(
                  onPressed: onUpgradeTap,
                  child: const Text('Unlock →'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
