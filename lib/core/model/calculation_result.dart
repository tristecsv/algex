import 'package:algex/core/model/iteration_data.dart';

class CalculationResult {
  final double finalValue;
  final double realValue;
  final int iterations;
  final List<IterationData> history;

  CalculationResult({
    required this.finalValue,
    required this.realValue,
    required this.iterations,
    required this.history,
  });
}
