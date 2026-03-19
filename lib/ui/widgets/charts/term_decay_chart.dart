import 'dart:math';
import 'package:algex/core/model/iteration_data.dart';
import 'package:algex/ui/widgets/charts/chart_card.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class TermDecayChart extends StatelessWidget {
  final List<IterationData> iterations;

  const TermDecayChart({super.key, required this.iterations});

  @override
  Widget build(BuildContext context) {
    if (iterations.isEmpty) return const SliverToBoxAdapter(child: SizedBox());

    final termSpots = chartValidSpots(
      iterations.map((e) {
        final absTerm = e.term.abs();
        final y = absTerm == 0 ? double.negativeInfinity : log(absTerm) / ln10;
        return FlSpot(e.n.toDouble(), y);
      }).toList(),
    );

    if (termSpots.isEmpty) return const ChartUnavailable();

    final yInterval = chartAutoInterval([termSpots]);
    final pointCount = iterations.last.n + 1;

    return ChartCard(
      title: 'Decaimiento del término (log₁₀)',
      legend: const [
        ChartLegendItem(
          color: Colors.purple,
          label: 'log₁₀(|xⁿ / n!|)',
        ),
      ],
      chartBuilder: (width) {
        final xInterval = chartXInterval(width, pointCount);

        return LineChart(
          LineChartData(
            minX: 0,
            maxX: iterations.last.n.toDouble(),
            gridData: chartGrid(yInterval: yInterval, xInterval: xInterval),
            titlesData: chartTitles(
              bottomLabel: 'Iteración',
              leftLabel: 'log₁₀(|término|)',
              yInterval: yInterval,
              xInterval: xInterval,
            ),
            borderData: chartBorder,
            clipData: FlClipData.none(),
            lineBarsData: [
              LineChartBarData(
                spots: termSpots,
                isCurved: false,
                barWidth: 3,
                color: Colors.purple,
                dotData: FlDotData(show: pointCount <= 20),
              ),
            ],
          ),
        );
      },
    );
  }
}
