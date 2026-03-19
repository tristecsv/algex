import 'dart:math';
import 'package:algex/core/model/iteration_data.dart';
import 'package:algex/ui/widgets/charts/chart_card.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class ErrorChart extends StatelessWidget {
  final List<IterationData> iterations;

  const ErrorChart({super.key, required this.iterations});

  @override
  Widget build(BuildContext context) {
    if (iterations.isEmpty) return const SliverToBoxAdapter(child: SizedBox());

    final hasRealValue = !iterations.first.relativeError.isNaN;
    final pointCount = iterations.last.n + 1;

    final approxSpots = chartValidSpots(
      iterations.map((e) {
        final v = e.approxError.abs();
        final y = v == 0 ? 0.0 : log(v) / ln10;
        return FlSpot(e.n.toDouble(), y);
      }).toList(),
    );

    final relativeSpots = hasRealValue
        ? chartValidSpots(
            iterations.map((e) {
              final v = e.relativeError.abs();
              final y = v == 0 ? 0.0 : log(v) / ln10;
              return FlSpot(e.n.toDouble(), y);
            }).toList(),
          )
        : <FlSpot>[];

    if (approxSpots.isEmpty) return const ChartUnavailable();

    final yInterval = chartAutoInterval([approxSpots, relativeSpots]);

    return ChartCard(
      title: 'Decaimiento del error (log₁₀)',
      legend: [
        const ChartLegendItem(
          color: Colors.orange,
          label: 'log₁₀(|error aproximado|)',
        ),
        if (hasRealValue)
          const ChartLegendItem(
            color: Colors.red,
            label: 'log₁₀(|error relativo|)',
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
              leftLabel: 'log₁₀(error)',
              yInterval: yInterval,
              xInterval: xInterval,
            ),
            borderData: chartBorder,
            clipData: FlClipData.none(),
            lineBarsData: [
              LineChartBarData(
                spots: approxSpots,
                isCurved: false,
                barWidth: 3,
                color: Colors.orange,
                dotData: FlDotData(show: pointCount <= 20),
              ),
              if (hasRealValue && relativeSpots.isNotEmpty)
                LineChartBarData(
                  spots: relativeSpots,
                  isCurved: false,
                  barWidth: 2,
                  color: Colors.red,
                  dashArray: [6, 4],
                  dotData: FlDotData(show: false),
                ),
            ],
          ),
        );
      },
    );
  }
}
