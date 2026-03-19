import 'package:algex/ui/state/settings_notifier.dart';
import 'package:algex/ui/widgets/adjust/adjust_section_header.dart';
import 'package:algex/ui/widgets/adjust/adjust_textfield.dart';
import 'package:algex/ui/widgets/adjust/chip_option.dart';
import 'package:algex/ui/widgets/base_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AdjustVisualization extends StatefulWidget {
  static const precisionOptions = [2, 4, 6, 8, 10, 12];

  const AdjustVisualization({super.key});

  @override
  State<AdjustVisualization> createState() => _AdjustVisualizationState();
}

class _AdjustVisualizationState extends State<AdjustVisualization> {
  final _precisionController = TextEditingController();
  final _precisionFormKey = GlobalKey<FormState>();
  late SettingsNotifier _notifier;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _precisionController.text =
          SettingsScope.of(context).settings.decimalPrecision.toString();

      _notifier.addListener(_syncControllers);
    });
  }

  @override
  void dispose() {
    _precisionController.dispose();
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
    _precisionController.text = settings.decimalPrecision.toString();
    _precisionFormKey.currentState?.validate();
  }

  void _applyPrecision() {
    if (!_precisionFormKey.currentState!.validate()) return;
    final parsed = int.parse(_precisionController.text.trim());
    final notifier = SettingsScope.of(context);
    notifier.settings = notifier.settings.copyWith(decimalPrecision: parsed);
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
              'Visualización',
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
            icon: Icons.visibility_rounded,
            title: 'Valor real',
            subtitle: 'Muestra e^x exacto junto a la aproximación.',
          ),
          const SizedBox(height: 14),
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => notifier.settings =
                settings.copyWith(showRealValue: !settings.showRealValue),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: settings.showRealValue
                    ? cs.primaryContainer.withOpacity(0.5)
                    : Colors.transparent,
                border: Border.all(
                  color: settings.showRealValue
                      ? cs.primary
                      : Colors.grey.shade200,
                  width: settings.showRealValue ? 1.8 : 1,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    settings.showRealValue ? 'Activado' : 'Desactivado',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: settings.showRealValue
                          ? cs.primary
                          : cs.onSurface.withOpacity(0.4),
                    ),
                  ),
                  Switch.adaptive(
                    value: settings.showRealValue,
                    onChanged: (v) =>
                        notifier.settings = settings.copyWith(showRealValue: v),
                  ),
                ],
              ),
            ),
          ),

          // --------------------

          const SizedBox(height: 20),
          const AdjustSectionHeader(
            icon: Icons.numbers_rounded,
            title: 'Decimales a mostrar',
            subtitle: 'Cifras decimales en los resultados.',
          ),
          const SizedBox(height: 14),
          ListChips<int>(
            options: AdjustVisualization.precisionOptions,
            selected: settings.decimalPrecision,
            labelBuilder: (v) => v.toString(),
            onTap: (v) {
              notifier.settings = settings.copyWith(decimalPrecision: v);
              _precisionController.text = v.toString();
              _precisionFormKey.currentState?.validate();
            },
          ),
          const SizedBox(height: 14),
          Form(
            key: _precisionFormKey,
            child: AdjustTextField(
              controller: _precisionController,
              label: 'Valor personalizado',
              hint: 'Ej. 7',
              prefixIcon: Icons.edit_rounded,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              textInputAction: TextInputAction.done,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Campo requerido';
                final parsed = int.tryParse(v.trim());
                if (parsed == null || parsed < 1) return 'Debe ser mayor a 0';
                return null;
              },
              onFieldSubmitted: (_) => _applyPrecision(),
              onChanged: (_) => _applyPrecision(),
            ),
          ),
        ],
      ),
    );
  }
}
