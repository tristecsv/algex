import 'package:algex/core/service/exp_calculator.dart';
import 'package:algex/core/model/calculation_result.dart';
import 'package:algex/ui/state/settings_notifier.dart';
import 'package:algex/ui/pages/settings_page.dart';
import 'package:algex/ui/widgets/charts/convergence_chart.dart';
import 'package:algex/ui/widgets/charts/error_chart.dart';
import 'package:algex/ui/widgets/charts/significant_figures_chart.dart';
import 'package:algex/ui/widgets/charts/term_decay_chart.dart';
import 'package:algex/ui/widgets/iterations_view.dart';
import 'package:algex/ui/widgets/result_summary_card.dart';
import 'package:algex/ui/widgets/mode_toggle.dart';
import 'package:algex/ui/widgets/input_sliver.dart';
import 'package:algex/ui/widgets/algex_sliver_appbar.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _xController = TextEditingController();

  CalculationResult? result;
  ViewMode _viewMode = ViewMode.iterations;
  double _usedTolerance = 1e-6;

  void _calculateTaylor() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final x = double.parse(_xController.text.trim());
    final settings = SettingsScope.of(context).settings;

    setState(() {
      result = ExpCalculator.calculate(x, settings: settings);
      _usedTolerance = settings.tolerance;
    });
  }

  @override
  void dispose() {
    _xController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlue.shade50,
      body: CustomScrollView(
        slivers: [
          AlgexSliverAppBar(
            title: 'Aproximacion de eˣ',
            subtitle: 'Serie de Taylor',
            onAction: () async {
              await SettingsPage.open(context);
            },
            actionIcon: Icons.tune_rounded,
            actionTooltip: 'Configuración',
          ),
          InputSliver(
            formKey: _formKey,
            controller: _xController,
            onSubmit: _calculateTaylor,
          ),
          if (result != null) ...[
            ResultSummaryCard(
              realValue: result!.realValue,
              approxValue: result!.finalValue,
              approxError: result!.history.last.approxError,
              absoluteError: result!.history.last.absoluteError,
              percentError: result!.history.last.percentError,
              significantFigures: result!.history.last.significantFigures,
              iterations: result!.iterations,
              tolerance: _usedTolerance,
            ),
            ModeToggle(
              selectedMode: _viewMode,
              onChanged: (mode) {
                setState(() => _viewMode = mode);
              },
            ),
            if (_viewMode == ViewMode.iterations)
              IterationsView(
                result: result!,
                tolerance: _usedTolerance,
              ),
            if (_viewMode == ViewMode.charts) ...[
              ConvergenceChart(
                iterations: result!.history,
                realValue: result!.realValue,
              ),
              TermDecayChart(iterations: result!.history),
              ErrorChart(iterations: result!.history),
              SignificantFiguresChart(iterations: result!.history),
            ],
          ]
        ],
      ),
    );
  }
}
