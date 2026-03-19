import 'dart:math';
import 'package:algex/core/model/iteration_data.dart';
import 'package:algex/ui/widgets/charts/chart_card.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class SignificantFiguresChart extends StatelessWidget {
  final List<IterationData> iterations;

  const SignificantFiguresChart({super.key, required this.iterations});

  @override
  Widget build(BuildContext context) {
    if (iterations.isEmpty) return const SliverToBoxAdapter(child: SizedBox());

    final hasRealValue = !iterations.first.relativeError.isNaN;
    if (!hasRealValue) {
      return const ChartUnavailable(
        message:
            'Las cifras significativas requieren valor real. Cambia a tolerancia absoluta en ajustes.',
      );
    }

    final cs = Theme.of(context).colorScheme;
    final pointCount = iterations.last.n + 1;

    final sigFigSpots = chartValidSpots(
      iterations
          .map((e) => FlSpot(e.n.toDouble(), e.significantFigures.toDouble()))
          .toList(),
    );

    final logErrorSpots = chartValidSpots(
      iterations.map((e) {
        final relError = e.relativeError.abs();
        final y = relError == 0 ? 0.0 : -log(relError) / ln10;
        return FlSpot(e.n.toDouble(), y);
      }).toList(),
    );

    if (sigFigSpots.isEmpty && logErrorSpots.isEmpty) {
      return const ChartUnavailable();
    }

    final yInterval = chartAutoInterval([sigFigSpots, logErrorSpots]);

    return ChartCard(
      title: 'Justificación de cifras significativas',
      legend: [
        ChartLegendItem(color: cs.primary, label: 'Cifras significativas'),
        const ChartLegendItem(
          color: Colors.green,
          label: '−log₁₀(error relativo)',
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
              yDecimals: 1,
            ),
            borderData: chartBorder,
            clipData: FlClipData.none(),
            lineBarsData: [
              LineChartBarData(
                spots: sigFigSpots,
                isCurved: false,
                barWidth: 3,
                color: cs.primary,
                dotData: FlDotData(show: pointCount <= 20),
              ),
              LineChartBarData(
                spots: logErrorSpots,
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
