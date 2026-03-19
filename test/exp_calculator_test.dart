import 'dart:math';
import 'package:algex/core/model/settings.dart';
import 'package:algex/core/service/exp_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Settings abs({double tol = 1e-6, int maxIter = 100}) => Settings(
        toleranceType: ToleranceType.absolute,
        tolerance: tol,
        maxIterations: maxIter,
      );

  Settings approx({double tol = 1e-6, int maxIter = 100}) => Settings(
        toleranceType: ToleranceType.approximate,
        tolerance: tol,
        maxIterations: maxIter,
      );

  group('exactitud', () {
    test('e^0 = 1', () {
      expect(ExpCalculator.calculate(0).finalValue, closeTo(1.0, 1e-10));
    });

    test('e^1 ≈ e', () {
      expect(ExpCalculator.calculate(1).finalValue, closeTo(exp(1), 1e-6));
    });

    test('e^-1 ≈ 1/e', () {
      expect(ExpCalculator.calculate(-1).finalValue, closeTo(exp(-1), 1e-6));
    });

    test('e^2 ≈ 7.389', () {
      expect(ExpCalculator.calculate(2).finalValue, closeTo(exp(2), 1e-6));
    });

    test('x negativo grande converge', () {
      expect(ExpCalculator.calculate(-3, settings: abs()).finalValue,
          closeTo(exp(-3), 1e-6));
    });

    test('x grande converge con tolerancia menos estricta', () {
      final r =
          ExpCalculator.calculate(10, settings: abs(tol: 1e-3, maxIter: 200));
      expect(r.finalValue, closeTo(exp(10), 1e-1));
    });
  });

  group('tolerancia absoluta', () {
    test('realValue es exp(x)', () {
      final r = ExpCalculator.calculate(1, settings: abs());
      expect(r.realValue, closeTo(exp(1), 1e-10));
    });

    test('se detiene cuando absoluteError < tolerancia', () {
      const tol = 1e-6;
      final r = ExpCalculator.calculate(1, settings: abs(tol: tol));
      expect(r.history.last.absoluteError, lessThan(tol));
    });

    test('absoluteError decrece con cada iteración', () {
      final errors = ExpCalculator.calculate(1, settings: abs())
          .history
          .map((d) => d.absoluteError)
          .toList();
      for (int i = 1; i < errors.length; i++) {
        expect(errors[i], lessThanOrEqualTo(errors[i - 1] + 1e-15));
      }
    });

    test('percentError = relativeError × 100', () {
      final history = ExpCalculator.calculate(1, settings: abs()).history;
      for (final d in history) {
        if (!d.relativeError.isNaN) {
          expect(d.percentError, closeTo(d.relativeError * 100, 1e-10));
        }
      }
    });

    test('n=0 tiene approxError NaN (sin iteración previa)', () {
      final n0 = ExpCalculator.calculate(1, settings: abs()).history.first;
      expect(n0.approxError, isNaN);
    });
  });

  group('tolerancia aproximada', () {
    test('realValue es NaN', () {
      expect(ExpCalculator.calculate(1, settings: approx()).realValue, isNaN);
    });

    test('absoluteError, relativeError y percentError son NaN', () {
      final history = ExpCalculator.calculate(1, settings: approx()).history;
      for (final d in history) {
        expect(d.absoluteError, isNaN);
        expect(d.relativeError, isNaN);
        expect(d.percentError, isNaN);
      }
    });

    test('se detiene cuando approxError < tolerancia', () {
      const tol = 1e-6;
      final r = ExpCalculator.calculate(1, settings: approx(tol: tol));
      expect(r.history.last.approxError, lessThan(tol));
    });

    test('resultado aproximado es razonablemente correcto', () {
      expect(ExpCalculator.calculate(1, settings: approx()).finalValue,
          closeTo(exp(1), 1e-4));
    });
  });

  group('estructura', () {
    test('iterations == history.length', () {
      final r = ExpCalculator.calculate(1);
      expect(r.iterations, equals(r.history.length));
    });

    test('finalValue == history.last.partialSum', () {
      final r = ExpCalculator.calculate(1);
      expect(r.finalValue, equals(r.history.last.partialSum));
    });

    test('n es secuencial en history', () {
      final history = ExpCalculator.calculate(1).history;
      for (int i = 0; i < history.length; i++) {
        expect(history[i].n, equals(i));
      }
    });

    test('respeta maxIterations si no converge', () {
      final r =
          ExpCalculator.calculate(1, settings: abs(tol: 1e-100, maxIter: 5));
      expect(r.iterations, equals(5));
    });

    test('mínimo 2 iteraciones (criterio de parada requiere n > 0)', () {
      final r = ExpCalculator.calculate(1, settings: abs(tol: 999));
      expect(r.iterations, greaterThanOrEqualTo(2));
    });
  });

  group('significantFigures', () {
    test('crece con las iteraciones', () {
      final history = ExpCalculator.calculate(1, settings: abs()).history;
      expect(history.last.significantFigures,
          greaterThan(history.first.significantFigures));
    });

    test('es 0 en modo aproximado', () {
      final history = ExpCalculator.calculate(1, settings: approx()).history;
      expect(history.every((d) => d.significantFigures == 0), isTrue);
    });
  });

  group('Settings.copyWith', () {
    const base = Settings();

    test('sin argumentos conserva todos los valores', () {
      final copy = base.copyWith();
      expect(copy.maxIterations, equals(base.maxIterations));
      expect(copy.tolerance, equals(base.tolerance));
      expect(copy.toleranceType, equals(base.toleranceType));
      expect(copy.showRealValue, equals(base.showRealValue));
      expect(copy.decimalPrecision, equals(base.decimalPrecision));
    });

    test('cada campo se puede cambiar independientemente', () {
      expect(base.copyWith(maxIterations: 50).maxIterations, equals(50));
      expect(base.copyWith(tolerance: 1e-10).tolerance, equals(1e-10));
      expect(base.copyWith(showRealValue: false).showRealValue, isFalse);
      expect(base.copyWith(decimalPrecision: 6).decimalPrecision, equals(6));
      expect(
        base.copyWith(toleranceType: ToleranceType.approximate).toleranceType,
        equals(ToleranceType.approximate),
      );
    });
  });
}
