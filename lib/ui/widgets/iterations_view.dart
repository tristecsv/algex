import 'package:algex/core/model/iteration_data.dart';
import 'package:algex/core/model/calculation_result.dart';
import 'package:algex/ui/state/settings_notifier.dart';
import 'package:algex/ui/widgets/base_card.dart';
import 'package:flutter/material.dart';

class IterationsView extends StatelessWidget {
  final CalculationResult result;
  final double tolerance;

  const IterationsView({
    super.key,
    required this.result,
    required this.tolerance,
  });

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      sliver: SliverList.builder(
        itemCount: result.history.length,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _IterationCard(
            data: result.history[index],
            hasRealValue: !result.realValue.isNaN,
            tolerance: tolerance,
          ),
        ),
      ),
    );
  }
}

class _IterationCard extends StatelessWidget {
  final IterationData data;
  final bool hasRealValue;
  final double tolerance;

  const _IterationCard({
    required this.data,
    required this.hasRealValue,
    required this.tolerance,
  });

  String _fmt(double value, int decimals) {
    if (value.isNaN || value.isInfinite) return '—';
    return value.toStringAsFixed(decimals);
  }

  Color _errorColor(BuildContext context, double error) {
    if (error.isNaN || error.isInfinite) {
      return Theme.of(context).colorScheme.onSurface.withOpacity(0.3);
    }
    if (error <= tolerance) return Colors.green;
    if (error <= tolerance * 100) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final decimals = SettingsScope.of(context).settings.decimalPrecision;
    final cs = Theme.of(context).colorScheme;

    // Tiles preconstruidos — mismos en wide y compact
    final infoTiles = [
      _InfoTile(label: 'Suma parcial', value: _fmt(data.partialSum, decimals)),
      _InfoTile(label: 'Término', value: _fmt(data.term, decimals)),
      if (hasRealValue)
        _InfoTile(
          label: 'Cifras significativas',
          value: data.significantFigures.toString(),
        ),
    ];

    final errorTiles = [
      _ErrorTile(
        label: 'Error aproximado',
        value: _fmt(data.approxError, decimals),
        color: _errorColor(context, data.approxError),
      ),
      if (hasRealValue) ...[
        _ErrorTile(
          label: 'Error absoluto',
          value: _fmt(data.absoluteError, decimals),
          color: _errorColor(context, data.absoluteError),
        ),
        _ErrorTile(
          label: 'Error porcentual',
          value: data.percentError.isNaN
              ? '—'
              : '${_fmt(data.percentError, decimals)}%',
          color: _errorColor(context, data.percentError),
        ),
      ],
    ];

    return BaseCard(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'n = ${data.n}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'monospace',
                    color: cs.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Divider(
                  color: cs.onSurface.withOpacity(0.08),
                  thickness: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 600) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _TileColumn(tiles: infoTiles),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _TileColumn(tiles: errorTiles),
                    ),
                  ],
                );
              }
              return _TileColumn(
                tiles: [
                  ...infoTiles,
                  Divider(height: 12, color: cs.onSurface.withOpacity(0.08)),
                  ...errorTiles,
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _TileColumn extends StatelessWidget {
  final List<Widget> tiles;

  const _TileColumn({required this.tiles});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < tiles.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          tiles[i],
        ],
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;

  const _InfoTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isUnavailable = value == '—';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isUnavailable
            ? cs.surfaceVariant.withOpacity(0.2)
            : cs.primaryContainer.withOpacity(0.4),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: cs.onSurface.withOpacity(isUnavailable ? 0.3 : 0.8),
                letterSpacing: 0.3,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              fontFamily: 'monospace',
              color:
                  isUnavailable ? cs.onSurface.withOpacity(0.25) : cs.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _ErrorTile({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isUnavailable = value == '—';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isUnavailable ? Colors.transparent : color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isUnavailable
              ? Colors.grey.withOpacity(0.15)
              : color.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isUnavailable
                    ? Colors.grey.withOpacity(0.5)
                    : color.withOpacity(0.8),
                letterSpacing: 0.4,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              fontFamily: 'monospace',
              color: isUnavailable ? Colors.grey.withOpacity(0.4) : color,
            ),
          ),
        ],
      ),
    );
  }
}
