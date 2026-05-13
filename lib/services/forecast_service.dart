class ForecastResult {
  final double eac;
  final double etc;
  final double vac;
  final double tcpii;
  final double tcpis;
  final String methodology;
  final DateTime forecastDate;
  final double confidenceLevel;

  ForecastResult({
    required this.eac,
    required this.etc,
    required this.vac,
    required this.tcpii,
    required this.tcpis,
    required this.methodology,
    required this.forecastDate,
    required this.confidenceLevel,
  });
}

class ForecastService {
  /// Calculate EAC (Estimate at Completion) and related metrics using standard EVM formulas.
  ///
  /// [methodology] can be:
  ///   - 'formula' (default): EAC = BAC / CPI
  ///   - 'manual': user-supplied EAC override
  ///   - 'riskBased': incorporates confidence level
  static ForecastResult calculateEac({
    required double bac,
    required double ev,
    required double ac,
    required double pv,
    String methodology = 'formula',
    double? manualEac,
  }) {
    if (methodology == 'manual' && manualEac != null) {
      final eac = manualEac;
      return ForecastResult(
        eac: eac,
        etc: eac - ac,
        vac: bac - eac,
        tcpii: _computeTcpii(bac, ev, ac),
        tcpis: _computeTcpis(bac, ev, eac, ac),
        methodology: 'manual',
        forecastDate: DateTime.now(),
        confidenceLevel: 0.5,
      );
    }

    final cpi = ac > 0 ? ev / ac : 1.0;
    final spi = pv > 0 ? ev / pv : 1.0;
    final eac = cpi > 0 ? bac / cpi : bac;
    final etc = eac - ac;
    final vac = bac - eac;
    final tcpii = _computeTcpii(bac, ev, ac);
    final tcpis = _computeTcpis(bac, ev, eac, ac);
    final confidence = _computeConfidence(cpi, spi);

    return ForecastResult(
      eac: eac,
      etc: etc,
      vac: vac,
      tcpii: tcpii,
      tcpis: tcpis,
      methodology: methodology,
      forecastDate: DateTime.now(),
      confidenceLevel: confidence,
    );
  }

  static double _computeTcpii(double bac, double ev, double ac) {
    return (bac - ac) > 0 ? (bac - ev) / (bac - ac) : 1.0;
  }

  static double _computeTcpis(double bac, double ev, double eac, double ac) {
    return (eac - ac) > 0 ? (bac - ev) / (eac - ac) : 1.0;
  }

  /// Simple heuristic: closer to 1.0 = higher confidence.
  static double _computeConfidence(double cpi, double spi) {
    final cpiConf = 1.0 - (cpi - 1.0).abs();
    final spiConf = 1.0 - (spi - 1.0).abs();
    return ((cpiConf + spiConf) / 2).clamp(0, 1);
  }
}
