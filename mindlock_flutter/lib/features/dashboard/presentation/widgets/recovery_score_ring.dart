import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';

class RecoveryScoreRing extends StatelessWidget {
  final int score;

  const RecoveryScoreRing({super.key, required this.score});

  @override
  Widget build(BuildContext context) {
    final color = _scoreColor(score);

    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 100,
            width: 100,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    startDegreeOffset: -90,
                    sectionsSpace: 0,
                    centerSpaceRadius: 36,
                    sections: [
                      PieChartSectionData(
                        value: score.toDouble(),
                        color: color,
                        radius: 12,
                        showTitle: false,
                      ),
                      PieChartSectionData(
                        value: (100 - score).toDouble(),
                        color: AppColors.surfaceHighlight,
                        radius: 12,
                        showTitle: false,
                      ),
                    ],
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$score',
                      style: AppTypography.statMedium.copyWith(fontSize: 24, color: color),
                    ),
                    Text('/ 100', style: AppTypography.caption),
                  ],
                ),
              ],
            ),
          ),
          AppSpacing.vGap(AppSpacing.sm),
          Text('Recovery', style: AppTypography.labelSmall),
          Text(_scoreLabel(score), style: AppTypography.caption.copyWith(color: color)),
        ],
      ),
    );
  }

  Color _scoreColor(int score) {
    if (score >= 80) return AppColors.recoveredTime;
    if (score >= 60) return AppColors.brandSecondary;
    if (score >= 40) return AppColors.warning;
    return AppColors.error;
  }

  String _scoreLabel(int score) {
    if (score >= 80) return 'Excellent';
    if (score >= 60) return 'Good';
    if (score >= 40) return 'Improving';
    if (score >= 20) return 'Struggling';
    return 'Just starting';
  }
}
