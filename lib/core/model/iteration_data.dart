class IterationData {
  final int n;
  final double term;
  final double partialSum;
  final double absoluteError;
  final double relativeError;
  final double percentError;
  final double approxError;
  final int significantFigures;

  IterationData({
    required this.n,
    required this.term,
    required this.partialSum,
    required this.absoluteError,
    required this.relativeError,
    required this.percentError,
    required this.approxError,
    required this.significantFigures,
  });
}
