import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:version/core/constants/colors.dart';
import 'package:version/features/goals/providers/goal_providers.dart';

class MonthlySavingsChart extends ConsumerWidget {
  const MonthlySavingsChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monthlySavingsAsync = ref.watch(monthlySavingsProvider);

    return AspectRatio(
      aspectRatio: 1.7,
      child: monthlySavingsAsync.when(
        data: (data) {
          if (data.isEmpty) {
            return const Center(
              child: Text('No savings data for the last 6 months.'),
            );
          }
          return BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: _calculateMaxY(data),
              barTouchData: BarTouchData(enabled: true),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final monthStr = data[value.toInt()]['month'];
                      final month = DateFormat('yyyy-MM').parse(monthStr);
                      return SideTitleWidget(
                        axisSide: meta.axisSide,
                        child: Text(
                          DateFormat('MMM').format(month),
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: AppColors.textMid),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: _calculateMaxY(data) / 4,
                getDrawingHorizontalLine: (_) => const FlLine(
                  color: AppColors.divider,
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: false),
              barGroups: data.asMap().entries.map((entry) {
                final index = entry.key;
                final value = entry.value['total'] as num;
                return BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: value.toDouble(),
                      color: AppColors.primaryGold,
                      width: 16,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(6),
                        topRight: Radius.circular(6),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) =>
            const Center(child: Text('Could not load chart data.')),
      ),
    );
  }

  double _calculateMaxY(List<Map<String, dynamic>> data) {
    double maxY = 0;
    for (var item in data) {
      final total = (item['total'] as num).toDouble();
      if (total > maxY) {
        maxY = total;
      }
    }
    return maxY * 1.2; // Add 20% padding
  }
}
