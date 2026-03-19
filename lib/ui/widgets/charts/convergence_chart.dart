import 'package:algex/core/model/iteration_data.dart';
import 'package:algex/ui/widgets/charts/chart_card.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class ConvergenceChart extends StatelessWidget {
  final List<IterationData> iterations;
  final double realValue;

  const ConvergenceChart({
    super.key,
    required this.iterations,
    required this.realValue,
  });

  @override
  Widget build(BuildContext context) {
    if (iterations.isEmpty) return const SliverToBoxAdapter(child: SizedBox());

    final cs = Theme.of(context).colorScheme;
    final hasRealValue = !realValue.isNaN && realValue.isFinite;

    final approxSpots = chartValidSpots(
      iterations.map((e) => FlSpot(e.n.toDouble(), e.partialSum)).toList(),
    );

    if (approxSpots.isEmpty) {
      return const ChartUnavailable(
        message: 'No hay datos de convergencia disponibles.',
      );
    }

    final yInterval = chartAutoInterval([approxSpots]);
    final pointCount = iterations.last.n + 1;

    return ChartCard(
      title: 'Convergencia del método',
      legend: [
        ChartLegendItem(color: cs.primary, label: 'Valor aproximado'),
        if (hasRealValue)
          const ChartLegendItem(
            color: Colors.green,
            label: 'Valor real (referencia)',
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
              leftLabel: 'Valor',
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
                color: cs.primary,
                dotData: FlDotData(
                  show: pointCount <= 20,
                ),
              ),
              if (hasRealValue)
                LineChartBarData(
                  spots: [
                    FlSpot(0, realValue),
                    FlSpot(iterations.last.n.toDouble(), realValue),
                  ],
                  isCurved: false,
                  barWidth: 2,
                  color: Colors.green,
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
