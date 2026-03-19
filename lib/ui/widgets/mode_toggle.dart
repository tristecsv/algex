import 'package:flutter/material.dart';

enum ViewMode { iterations, charts }

class ModeToggle extends StatelessWidget {
  final ViewMode selectedMode;
  final ValueChanged<ViewMode> onChanged;

  const ModeToggle({
    super.key,
    required this.selectedMode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: LayoutBuilder(
              builder: (_, constraints) {
                final itemWidth = constraints.maxWidth / 2;
                final showLabel = itemWidth >= 150;

                return Container(
                  height: 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    color: cs.surface,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(6),
                  child: Stack(
                    children: [
                      AnimatedAlign(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                        alignment: selectedMode == ViewMode.iterations
                            ? Alignment.centerLeft
                            : Alignment.centerRight,
                        child: FractionallySizedBox(
                          widthFactor: 0.5,
                          child: Container(
                            height: 40,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              gradient: LinearGradient(
                                colors: [
                                  cs.primary,
                                  cs.primary.withOpacity(0.85),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: _ToggleItem(
                              icon: Icons.list_alt_rounded,
                              label: 'Iteraciones',
                              selected: selectedMode == ViewMode.iterations,
                              showLabel: showLabel,
                              onTap: () => onChanged(ViewMode.iterations),
                            ),
                          ),
                          Expanded(
                            child: _ToggleItem(
                              icon: Icons.show_chart_rounded,
                              label: 'Gráficas',
                              selected: selectedMode == ViewMode.charts,
                              showLabel: showLabel,
                              onTap: () => onChanged(ViewMode.charts),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _ToggleItem extends StatelessWidget {
  static const double _fontSize = 15;

  final IconData icon;
  final String label;
  final bool selected;
  final bool showLabel;
  final VoidCallback onTap;

  const _ToggleItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.showLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = selected ? Colors.white : cs.onSurface.withOpacity(0.75);

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Center(
        child: TweenAnimationBuilder<Color?>(
          tween: ColorTween(end: color),
          duration: const Duration(milliseconds: 200),
          builder: (_, animatedColor, __) => Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: _fontSize + 4, color: animatedColor),
              if (showLabel) ...[
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: _fontSize,
                    fontWeight: FontWeight.w600,
                    color: animatedColor,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
