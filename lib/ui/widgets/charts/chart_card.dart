import 'package:algex/ui/widgets/base_card.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class ChartCard extends StatelessWidget {
  final String title;
  final List<ChartLegendItem> legend;

  final Widget Function(double width) chartBuilder;
  final double chartHeight;

  const ChartCard({
    super.key,
    required this.title,
    required this.legend,
    required this.chartBuilder,
    this.chartHeight = 280,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: BaseCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: legend.map((item) => _LegendDot(item: item)).toList(),
              ),
              const SizedBox(height: 20),
              LayoutBuilder(
                builder: (context, constraints) {
                  return SizedBox(
                    height: chartHeight,
                    child: chartBuilder(constraints.maxWidth),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class ChartLegendItem {
  final Color color;
  final String label;

  const ChartLegendItem({required this.color, required this.label});
}

class _LegendDot extends StatelessWidget {
  final ChartLegendItem item;

  const _LegendDot({required this.item});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: item.color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        Text(item.label, style: const TextStyle(fontSize: 13)),
      ],
    );
  }
}


class ChartUnavailable extends StatelessWidget {
  final String message;

  const ChartUnavailable({
    super.key,
    this.message = 'No disponible con error aproximado.',
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: BaseCard(
          child: Row(
            children: [
              Icon(
                Icons.bar_chart_rounded,
                size: 32,
                color: cs.onSurface.withOpacity(0.2),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    fontSize: 13,
                    color: cs.onSurface.withOpacity(0.45),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Calcula el intervalo automático del eje Y para una o más series.
double chartAutoInterval(List<List<FlSpot>> series) {
  final values =
      series.expand((s) => s).map((s) => s.y).where((y) => y.isFinite).toList();

  if (values.isEmpty) return 1;

  final max = values.reduce((a, b) => a > b ? a : b);
  final min = values.reduce((a, b) => a < b ? a : b);
  final range = (max - min).abs();

  return range == 0 ? 1 : range / 5;
}

/// Calcula el intervalo del eje X según el ancho disponible y el total de puntos.
double chartXInterval(double availableWidth, int pointCount) {
  if (pointCount <= 1) return 1;

  // ~40px por label como mínimo para evitar solapamiento
  final maxLabels = (availableWidth / 40).floor();
  if (maxLabels <= 0) return pointCount.toDouble();

  final interval = (pointCount / maxLabels).ceil().toDouble();
  return interval < 1 ? 1 : interval;
}

/// Filtra spots con valores NaN o infinitos.
List<FlSpot> chartValidSpots(List<FlSpot> spots) {
  return spots.where((s) => s.y.isFinite).toList();
}

/// Configuración de ejes compartida entre todos los charts.
FlTitlesData chartTitles({
  required String bottomLabel,
  required String leftLabel,
  required double yInterval,
  required double xInterval,
  int yDecimals = 2,
  double leftReservedSize = 55,
}) {
  return FlTitlesData(
    bottomTitles: AxisTitles(
      axisNameSize: 28,
      axisNameWidget: Text(bottomLabel, style: const TextStyle(fontSize: 12)),
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: 36,
        interval: xInterval,
        getTitlesWidget: (value, meta) => Text(
          value.toInt().toString(),
          style: const TextStyle(fontSize: 11),
        ),
      ),
    ),
    leftTitles: AxisTitles(
      axisNameSize: 30,
      axisNameWidget: Text(leftLabel, style: const TextStyle(fontSize: 12)),
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: leftReservedSize,
        interval: yInterval,
        getTitlesWidget: (value, meta) => Text(
          value.toStringAsFixed(yDecimals),
          style: const TextStyle(fontSize: 11),
        ),
      ),
    ),
    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
  );
}

/// Border estándar para todos los charts.
FlBorderData get chartBorder => FlBorderData(
      show: true,
      border: Border.all(color: Colors.grey.shade300),
    );

/// Grid estándar para todos los charts.
FlGridData chartGrid({required double yInterval, required double xInterval}) =>
    FlGridData(
      show: true,
      drawVerticalLine: true,
      horizontalInterval: yInterval,
      verticalInterval: xInterval,
    );
