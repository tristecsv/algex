import 'package:algex/core/model/settings.dart';
import 'package:algex/ui/state/settings_notifier.dart';
import 'package:algex/ui/widgets/adjust/adjust_section_header.dart';
import 'package:algex/ui/widgets/adjust/adjust_textfield.dart';
import 'package:algex/ui/widgets/adjust/chip_option.dart';
import 'package:algex/ui/widgets/base_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AdjustConvergence extends StatefulWidget {
  static const maxIterPresets = [10, 25, 50, 100, 200, 500];
  static const tolerancePresets = [1e-3, 1e-4, 1e-6, 1e-8, 1e-10];

  const AdjustConvergence({super.key});

  @override
  State<AdjustConvergence> createState() => _AdjustConvergenceState();
}

class _AdjustConvergenceState extends State<AdjustConvergence> {
  final _iterController = TextEditingController();
  final _toleranceController = TextEditingController();
  final _iterFormKey = GlobalKey<FormState>();
  final _toleranceFormKey = GlobalKey<FormState>();
  late SettingsNotifier _notifier;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings = SettingsScope.of(context).settings;
      _iterController.text = settings.maxIterations.toString();
      _toleranceController.text = settings.tolerance.toString();

      _notifier.addListener(_syncControllers);
    });
  }

  @override
  void dispose() {
    _iterController.dispose();
    _toleranceController.dispose();
    _notifier.removeListener(_syncControllers);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _notifier = SettingsScope.of(context);
  }

  void _syncControllers() {
    final settings = SettingsScope.of(context).settings;
    _iterController.text = settings.maxIterations.toString();
    _toleranceController.text = settings.tolerance.toString();
    _iterFormKey.currentState?.validate();
    _toleranceFormKey.currentState?.validate();
  }

  void _applyIterations() {
    if (!_iterFormKey.currentState!.validate()) return;
    final parsed = int.parse(_iterController.text.trim());
    final notifier = SettingsScope.of(context);
    notifier.settings = notifier.settings.copyWith(maxIterations: parsed);
  }

  void _applyTolerance() {
    if (!_toleranceFormKey.currentState!.validate()) return;
    final parsed = double.parse(_toleranceController.text.trim());
    final notifier = SettingsScope.of(context);
    notifier.settings = notifier.settings.copyWith(tolerance: parsed);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final notifier = SettingsScope.of(context);
    final settings = notifier.settings;

    return BaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              'Convergencia',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Divider(color: cs.onSurface.withOpacity(0.1), thickness: 1),

          // --------------------

          const SizedBox(height: 20),
          const AdjustSectionHeader(
            icon: Icons.track_changes_rounded,
            title: 'Criterio de parada',
            subtitle: 'Define cómo se mide el error para detener el cálculo.',
          ),
          const SizedBox(height: 14),
          ...ToleranceType.values.map(
            (type) => _ToleranceOption(
              type: type,
              selected: settings.toleranceType == type,
              onTap: () =>
                  notifier.settings = settings.copyWith(toleranceType: type),
            ),
          ),

          // --------------------

          const SizedBox(height: 20),
          const AdjustSectionHeader(
            title: 'Tolerancia',
            subtitle:
                'El cálculo se detiene cuando el error cae por debajo de este valor.',
            icon: Icons.adjust_rounded,
          ),
          const SizedBox(height: 14),
          ListChips<double>(
            options: AdjustConvergence.tolerancePresets,
            selected: settings.tolerance,
            labelBuilder: _formatTolerance,
            onTap: (v) {
              notifier.settings = settings.copyWith(tolerance: v);
              _toleranceController.text = v.toString();
              _toleranceFormKey.currentState?.validate();
            },
          ),
          const SizedBox(height: 14),
          Form(
            key: _toleranceFormKey,
            child: AdjustTextField(
              controller: _toleranceController,
              label: 'Valor personalizado',
              hint: 'Ej. 1e-7',
              prefixIcon: Icons.edit_rounded,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9eE+\-\.]')),
              ],
              textInputAction: TextInputAction.done,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Campo requerido';
                final parsed = double.tryParse(v.trim());
                if (parsed == null || parsed <= 0) {
                  return 'Debe ser un número positivo (ej. 1e-6)';
                }
                return null;
              },
              onFieldSubmitted: (_) => _applyTolerance(),
              onChanged: (_) => _applyTolerance(),
            ),
          ),

          // --------------------

          const SizedBox(height: 20),
          const AdjustSectionHeader(
            title: 'Iteraciones máximas',
            subtitle: 'La serie se detiene al alcanzar este límite.',
            icon: Icons.repeat_rounded,
          ),
          const SizedBox(height: 14),
          ListChips<int>(
            options: AdjustConvergence.maxIterPresets,
            selected: settings.maxIterations,
            labelBuilder: (v) => v.toString(),
            onTap: (v) {
              notifier.settings = settings.copyWith(maxIterations: v);
              _iterController.text = v.toString();
              _iterFormKey.currentState?.validate();
            },
          ),
          const SizedBox(height: 14),
          Form(
            key: _iterFormKey,
            child: AdjustTextField(
              controller: _iterController,
              label: 'Valor personalizado',
              hint: 'Ej. 150',
              prefixIcon: Icons.numbers_rounded,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              textInputAction: TextInputAction.done,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Campo requerido';
                final parsed = int.tryParse(v.trim());
                if (parsed == null || parsed < 1) {
                  return 'Debe ser un entero mayor a 0';
                }
                return null;
              },
              onFieldSubmitted: (_) => _applyIterations(),
              onChanged: (_) => _applyIterations(),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatTolerance(double v) {
  if (v == 0) return '0';
  return v.toStringAsExponential(0).replaceAll('+', '');
}

class _ToleranceOption extends StatelessWidget {
  final ToleranceType type;
  final bool selected;
  final VoidCallback onTap;

  const _ToleranceOption({
    required this.type,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: selected
                ? cs.primaryContainer.withOpacity(0.5)
                : Colors.transparent,
            border: Border.all(
              color: selected ? cs.primary : Colors.grey.shade200,
              width: selected ? 1.8 : 1,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? cs.primary : Colors.transparent,
                  border: Border.all(
                    color: selected ? cs.primary : Colors.grey.shade400,
                    width: 2,
                  ),
                ),
                child: selected
                    ? Icon(Icons.check_rounded, size: 13, color: cs.onPrimary)
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      type.label,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: selected ? cs.primary : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      type.description,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
