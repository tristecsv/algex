import 'package:algex/ui/state/settings_notifier.dart';
import 'package:algex/ui/widgets/base_card.dart';
import 'package:flutter/material.dart';

class ResultSummaryCard extends StatelessWidget {
  final double realValue;
  final double approxValue;
  final double absoluteError;
  final double percentError;
  final double approxError;
  final double tolerance;
  final int significantFigures;
  final int iterations;

  const ResultSummaryCard({
    super.key,
    required this.realValue,
    required this.approxValue,
    required this.absoluteError,
    required this.percentError,
    required this.approxError,
    required this.tolerance,
    required this.significantFigures,
    required this.iterations,
  });

  String _fmt(double value, int decimals, {bool isPercent = false}) {
    if (value.isNaN || value.isInfinite) return '—';
    return value.toStringAsFixed(decimals) + (isPercent ? '%' : '');
  }

  Color _errorColor(BuildContext context, double error) {
    if (error.isNaN || error.isInfinite) {
      return Theme.of(context).colorScheme.primary;
    }
    if (error <= tolerance) return Colors.green;
    if (error <= tolerance * 100) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final settings = SettingsScope.of(context).settings;
    final decimals = settings.decimalPrecision;
    final hasRealValue = !realValue.isNaN;

    final approxWidget = _HighlightValue(
      label: 'Valor aproximado',
      value: _fmt(approxValue, decimals),
      color: cs.primary,
    );
    final realWidget = settings.showRealValue
        ? _HighlightValue(
            label: 'Valor real',
            value: _fmt(realValue, decimals),
            color: Colors.green,
          )
        : null;

    final metricRows = [
      [
        _Metric(
          label: 'Error aproximado',
          value: _fmt(approxError, decimals),
          icon: Icons.swap_horiz_rounded,
          color: _errorColor(context, approxError),
        ),
        _Metric(
          label: 'Error porcentual',
          value: _fmt(percentError, decimals, isPercent: true),
          icon: Icons.percent_rounded,
          color: _errorColor(context, percentError),
        ),
      ],
      [
        _Metric(
          label: 'Error absoluto',
          value: _fmt(absoluteError, decimals),
          icon: Icons.compress_rounded,
          color: _errorColor(context, absoluteError),
        ),
      ],
      [
        _Metric(
          label: 'Cifras significativas',
          value: hasRealValue ? significantFigures.toString() : '—',
          icon: Icons.looks_one_rounded,
        ),
        _Metric(
          label: 'Iteraciones',
          value: iterations.toString(),
          icon: Icons.repeat_rounded,
        ),
      ],
    ];

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: BaseCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Resumen de resultados',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              LayoutBuilder(
                builder: (_, constraints) {
                  final isWide = constraints.maxWidth > 600;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isWide && realWidget != null)
                        Row(
                          children: [
                            Expanded(child: realWidget),
                            const SizedBox(width: 8),
                            Expanded(child: approxWidget),
                          ],
                        )
                      else
                        Column(
                          children: [
                            if (realWidget != null) ...[
                              realWidget,
                              const SizedBox(height: 8),
                            ],
                            approxWidget,
                          ],
                        ),
                      const SizedBox(height: 16),
                      Divider(color: cs.onSurface.withOpacity(0.08)),
                      const SizedBox(height: 8),
                      if (!isWide)
                        _MetricColumn(
                          metrics: [for (final i in metricRows) ...i],
                        )
                      else
                        _MetricWide(rows: metricRows),
                    ],
                  );
                },
              ),
              if (!hasRealValue) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 14,
                      color: cs.onSurface.withOpacity(0.6),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Algunas métricas no están disponibles con error aproximado.',
                        style: TextStyle(
                          fontSize: 11,
                          color: cs.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricColumn extends StatelessWidget {
  final List<_Metric> metrics;
  const _MetricColumn({required this.metrics});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (int i = 0; i < metrics.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          _MetricTile(metric: metrics[i]),
        ],
      ],
    );
  }
}

class _MetricWide extends StatelessWidget {
  final List<List<_Metric>> rows;
  const _MetricWide({required this.rows});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (int i = 0; i < rows.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          Row(
            children: [
              for (int j = 0; j < rows[i].length; j++) ...[
                if (j > 0) const SizedBox(width: 8),
                Expanded(child: _MetricTile(metric: rows[i][j])),
              ],
            ],
          ),
        ],
      ],
    );
  }
}

class _Metric {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;

  const _Metric({
    required this.label,
    required this.value,
    required this.icon,
    this.color,
  });
}

class _HighlightValue extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _HighlightValue({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color.withOpacity(0.8),
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              fontFamily: 'monospace',
              color: color,
            ),
            softWrap: true,
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final _Metric metric;

  const _MetricTile({required this.metric});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = metric.color ?? cs.primary;
    final isUnavailable = metric.value == '—';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surfaceVariant.withOpacity(isUnavailable ? 0.2 : 0.4),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            metric.icon,
            size: 16,
            color: isUnavailable ? cs.onSurface.withOpacity(0.25) : color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  metric.label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface.withOpacity(isUnavailable ? 0.3 : 0.5),
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  metric.value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'monospace',
                    color:
                        isUnavailable ? cs.onSurface.withOpacity(0.25) : color,
                  ),
                  softWrap: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
