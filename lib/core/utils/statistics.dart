import 'dart:math' as math;

/// یک بازه‌ی هیستوگرام
class HistBin {
  const HistBin({required this.from, required this.to, required this.count});

  final double from;
  final double to;
  final int count;

  String get label =>
      '${from.toStringAsFixed(1)}–${to.toStringAsFixed(1)}';
}

/// توابع آمار مهندسی کیفیت — پیاده‌سازی سفارشی، کاملاً آفلاین.
class Stats {
  Stats._();

  static double mean(List<double> d) =>
      d.isEmpty ? 0 : d.reduce((a, b) => a + b) / d.length;

  /// انحراف معیار نمونه (n-1)
  static double stddev(List<double> d) {
    if (d.length < 2) return 0;
    final m = mean(d);
    final s = d.map((x) => (x - m) * (x - m)).reduce((a, b) => a + b);
    return math.sqrt(s / (d.length - 1));
  }

  static List<double> sorted(List<double> d) => List.of(d)..sort();

  static double quantile(List<double> sortedD, double q) {
    if (sortedD.isEmpty) return 0;
    final pos = (sortedD.length - 1) * q;
    final lo = pos.floor();
    final hi = pos.ceil();
    if (lo == hi) return sortedD[lo];
    return sortedD[lo] + (sortedD[hi] - sortedD[lo]) * (pos - lo);
  }

  static double median(List<double> d) => quantile(sorted(d), .5);

  /// (Q1, Q3)
  static ({double q1, double q3}) quartiles(List<double> d) {
    final s = sorted(d);
    return (q1: quantile(s, .25), q3: quantile(s, .75));
  }

  /// نقاط پرت با قاعده‌ی 1.5×IQR
  static List<double> outliers(List<double> d) {
    final (q1: q1, q3: q3) = quartiles(d);
    final iqr = q3 - q1;
    final lo = q1 - 1.5 * iqr;
    final hi = q3 + 1.5 * iqr;
    return d.where((x) => x < lo || x > hi).toList();
  }

  /// Cp = (USL−LSL) / 6σ — بدون حدود مشخص، صفر برمی‌گرداند
  static double cp({double? lsl, double? usl, required double sd}) {
    if (lsl == null || usl == null || sd <= 0) return 0;
    return (usl - lsl) / (6 * sd);
  }

  /// Cpk = min(USL−μ, μ−LSL) / 3σ — بدون حدود مشخص، صفر برمی‌گرداند
  static double cpk({double? lsl, double? usl, required double sd, required double m}) {
    if (lsl == null || usl == null || sd <= 0) return 0;
    return math.min((usl - m) / (3 * sd), (m - lsl) / (3 * sd));
  }

  /// ضریب همبستگی پیرسون R
  static double correlation(List<double> x, List<double> y) {
    final n = math.min(x.length, y.length);
    if (n < 2) return 0;
    final mx = mean(x.sublist(0, n));
    final my = mean(y.sublist(0, n));
    var sxy = 0.0, sxx = 0.0, syy = 0.0;
    for (var i = 0; i < n; i++) {
      final dx = x[i] - mx;
      final dy = y[i] - my;
      sxy += dx * dy;
      sxx += dx * dx;
      syy += dy * dy;
    }
    final den = math.sqrt(sxx * syy);
    return den <= 0 ? 0 : sxy / den;
  }

  /// حدود کنترل نمودار X (میانگین ± ۳σ)
  static ({double cl, double ucl, double lcl}) controlLimits(List<double> d) {
    final m = mean(d);
    final s = stddev(d);
    return (cl: m, ucl: m + 3 * s, lcl: m - 3 * s);
  }

  /// شاخص نقاط خارج از کنترل
  static List<int> outOfControlIndices(List<double> d) {
    final (cl: _, ucl: u, lcl: l) = controlLimits(d);
    return [
      for (var i = 0; i < d.length; i++)
        if (d[i] > u || d[i] < l) i,
    ];
  }

  /// ساخت بازه‌های هیستوگرام
  static List<HistBin> histogram(List<double> d, [int binCount = 8]) {
    if (d.isEmpty) return const [];
    final s = sorted(d);
    final min = s.first;
    final max = s.last;
    final width = ((max - min) / binCount).abs();
    final w = width == 0 ? 1.0 : width;
    final bins = [
      for (var i = 0; i < binCount; i++)
        HistBin(from: min + i * w, to: min + (i + 1) * w, count: 0),
    ];
    for (final v in d) {
      var idx = ((v - min) / w).floor();
      if (idx >= binCount) idx = binCount - 1;
      if (idx < 0) idx = 0;
      bins[idx] = HistBin(
          from: bins[idx].from, to: bins[idx].to, count: bins[idx].count + 1);
    }
    return bins;
  }

  /// آزمون t ولچ (برابری میانگین قبل/بعد) — معناداری ساده |t|≥2
  static ({double t, bool significant}) welchT(
      List<double> a, List<double> b) {
    if (a.length < 2 || b.length < 2) return (t: 0, significant: false);
    final ma = mean(a);
    final mb = mean(b);
    final va = stddev(a) * stddev(a) / a.length;
    final vb = stddev(b) * stddev(b) / b.length;
    final den = math.sqrt(va + vb);
    if (den <= 0) return (t: 0, significant: false);
    final t = (ma - mb) / den;
    return (t: t, significant: t.abs() >= 2.0);
  }

  /// تجزیه‌ی رشته‌ی اعداد (جداکننده: ویرگول/فاصله/خط جدید)
  static List<double> parseNumbers(String source) => [
        for (final m in RegExp(r'-?[0-9]+(?:[.,][0-9]+)?').allMatches(source))
          double.parse(m.group(0)!.replaceAll(',', '.')),
      ];
}
