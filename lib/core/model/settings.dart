enum ToleranceType { approximate, absolute }

extension ToleranceTypeX on ToleranceType {
  String get label => switch (this) {
        ToleranceType.approximate => 'Error aproximado',
        ToleranceType.absolute => 'Error absoluto',
      };

  String get description => switch (this) {
        ToleranceType.approximate => 'Compara iteraciones consecutivas.',
        ToleranceType.absolute => 'Compara contra el valor real.',
      };
}

class Settings {
  final int maxIterations;
  final double tolerance;
  final ToleranceType toleranceType;
  final bool showRealValue;
  final int decimalPrecision;

  const Settings({
    this.maxIterations = 100,
    this.tolerance = 1e-6,
    this.toleranceType = ToleranceType.absolute,
    this.showRealValue = true,
    this.decimalPrecision = 12,
  });

  Settings copyWith({
    int? maxIterations,
    double? tolerance,
    ToleranceType? toleranceType,
    bool? showRealValue,
    int? decimalPrecision,
  }) {
    return Settings(
      maxIterations: maxIterations ?? this.maxIterations,
      tolerance: tolerance ?? this.tolerance,
      toleranceType: toleranceType ?? this.toleranceType,
      showRealValue: showRealValue ?? this.showRealValue,
      decimalPrecision: decimalPrecision ?? this.decimalPrecision,
    );
  }
}
