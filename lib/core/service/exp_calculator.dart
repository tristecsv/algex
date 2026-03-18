import 'dart:math';
import 'package:algex/core/model/iteration_data.dart';
import 'package:algex/core/model/calculation_result.dart';
import 'package:algex/core/model/settings.dart';

class ExpCalculator {
  static CalculationResult calculate(
    double x, {
    Settings settings = const Settings(),
  }) {
    final bool useRealValue = settings.toleranceType == ToleranceType.absolute;
    final double realValue = useRealValue ? exp(x) : double.nan;

    double sum = 1.0;
    double term = 1.0;
    double previousSum = 0.0;

    final List<IterationData> history = [];

    for (int n = 0; n < settings.maxIterations; n++) {
      if (n > 0) {
        term = term * x / n;
        sum += term;
      }

      final double approxError =
          n > 0 && sum != 0 ? ((sum - previousSum) / sum).abs() : double.nan;

      final double absoluteError =
          useRealValue ? (realValue - sum).abs() : double.nan;

      final double relativeError =
          useRealValue ? absoluteError / realValue.abs() : double.nan;

      final double percentError =
          useRealValue ? relativeError * 100 : double.nan;

      int significantFigures = 0;
      if (useRealValue && relativeError > 0 && relativeError < 1) {
        significantFigures = max(0, (-log(relativeError) / ln10).floor());
      }

      history.add(
        IterationData(
          n: n,
          term: term,
          partialSum: sum,
          absoluteError: absoluteError,
          relativeError: relativeError,
          percentError: percentError,
          approxError: approxError,
          significantFigures: significantFigures,
        ),
      );

      if (n > 0) {
        final double errorToCheck = useRealValue ? absoluteError : approxError;
        if (errorToCheck < settings.tolerance) {
          return CalculationResult(
            finalValue: sum,
            realValue: realValue,
            iterations: n + 1,
            history: history,
          );
        }
      }

      previousSum = sum;
    }

    return CalculationResult(
      finalValue: sum,
      realValue: realValue,
      iterations: settings.maxIterations,
      history: history,
    );
  }
}
