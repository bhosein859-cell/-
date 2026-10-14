import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/utils/statistics.dart';

/// نقاشان نمودارهای آماری برای جاسازی در گزارش Word — خروجی باکیفیت و
/// مستقل از فریمورک‌های نمودار، قابل رندر با ChartImageRenderer.

double _drawTitle(Canvas canvas, String text, Size size) {
  final tp = TextPainter(
    text: TextSpan(
      text,
      style: const TextStyle(
          fontFamily: 'Vazirmatn', fontSize: 15, fontWeight: FontWeight.w800,
          color: Color(0xFF1E3A8A)),
    ),
    textDirection: TextDirection.rtl,
  )..layout();
  tp.paint(canvas, Offset(size.width - tp.width - 10, 6));
  return 34;
}

void _drawLabel(Canvas canvas, String text, double x, double y,
    {int size = 10, Color color = const Color(0xFF475569)}) {
  final tp = TextPainter(
    text: TextSpan(text,
        style: TextStyle(fontFamily: 'Vazirmatn', fontSize: size.toDouble(), color: color)),
    textDirection: TextDirection.rtl,
  )..layout();
  tp.paint(canvas, Offset(x, y));
}

/// هیستوگرام با خطوط حد و شاخص‌های قابلیت فرایند
class HistogramReportPainter extends CustomPainter {
  HistogramReportPainter({required this.data, this.lsl, this.usl});

  final List<double> data;
  final double? lsl, usl;

  @override
  void paint(Canvas canvas, Size size) {
    final top = _drawTitle(canvas, 'هیستوگرام توزیع داده‌ها', size);
    final bins = Stats.histogram(data);
    if (bins.isEmpty) return;
    final maxC = bins.map((b) => b.count).reduce((a, b) => a > b ? a : b);

    final rect = Rect.fromLTRB(50, top + 6, size.width - 20, size.height - 34);
    final barW = rect.width / bins.length;
    final paint = Paint()..color = AppColors.navyBlue.withValues(alpha: .85);

    for (var i = 0; i < bins.length; i++) {
      final h = bins[i].count / maxC * rect.height;
      canvas.drawRRect(
        RRect.fromRectAndCorners(
            Rect.fromLTWH(rect.left + i * barW + 1.5, rect.bottom - h,
                barW - 3, h),
            topRight: const Radius.circular(3),
            topLeft: const Radius.circular(3)),
        paint,
      );
      _drawLabel(canvas, '${bins[i].count}',
          rect.left + i * barW + barW / 2 - 4, rect.bottom - h - 13, size: 9);
      if (i % 2 == 0) {
        _drawLabel(canvas, bins[i].label,
            rect.left + i * barW, rect.bottom + 4, size: 8);
      }
    }

    // خطوط حدود
    if (lsl != null && usl != null && usl! > lsl!) {
      final span = bins.last.to - bins.first.from;
      double xOf(double v) =>
          rect.left + (v - bins.first.from) / span * rect.width;
      final lp = Paint()..color = AppColors.level3..strokeWidth = 1.6;
      canvas.drawLine(Offset(xOf(lsl!), rect.top - 4), Offset(xOf(lsl!), rect.bottom), lp);
      canvas.drawLine(Offset(xOf(usl!), rect.top - 4), Offset(xOf(usl!), rect.bottom), lp);
      _drawLabel(canvas, 'LSL', xOf(lsl!) - 12, rect.top - 16, color: AppColors.level3);
      _drawLabel(canvas, 'USL', xOf(usl!) - 12, rect.top - 16, color: AppColors.level3);
    }

    // آمار
    final m = Stats.mean(data);
    final sd = Stats.stddev(data);
    final cp = Stats.cp(lsl: lsl, usl: usl, sd: sd);
    final cpk = Stats.cpk(lsl: lsl, usl: usl, sd: sd, m: m);
    _drawLabel(
      canvas,
      'میانگین: ${m.toStringAsFixed(2)}   σ: ${sd.toStringAsFixed(2)}   '
      'Cp: ${cp.toStringAsFixed(2)}   Cpk: ${cpk.toStringAsFixed(2)}',
      54, size.height - 22, size: 11, color: AppColors.navyBlue);
  }

  @override
  bool shouldRepaint(covariant HistogramReportPainter o) => true;
}

/// نمودار کنترل با حدهای μ±3σ و نقاط خارج از کنترل
class ControlReportPainter extends CustomPainter {
  ControlReportPainter({required this.data});

  final List<double> data;

  @override
  void paint(Canvas canvas, Size size) {
    final top = _drawTitle(canvas, 'نمودار کنترل (μ±3σ)', size);
    if (data.length < 2) return;
    final (cl: cl, ucl: ucl, lcl: lcl) = Stats.controlLimits(data);
    final ooc = Stats.outOfControlIndices(data).toSet();

    final rect = Rect.fromLTRB(50, top + 8, size.width - 20, size.height - 26);
    final lo = [lcl, ...data].reduce((a, b) => a < b ? a : b);
    final hi = [ucl, ...data].reduce((a, b) => a > b ? a : b);
    final span = (hi - lo) == 0 ? 1.0 : (hi - lo);
    double xOf(int i) => rect.left + i / (data.length - 1) * rect.width;
    double yOf(double v) => rect.bottom - (v - lo) / span * rect.height;

    // خطوط حد
    for (final (v, label, c) in [
      (ucl, 'UCL', AppColors.level3),
      (cl, 'CL', AppColors.success),
      (lcl, 'LCL', AppColors.level3),
    ]) {
      final lp = Paint()
        ..color = c
        ..strokeWidth = 1.4;
      canvas.drawLine(Offset(rect.left, yOf(v)), Offset(rect.right, yOf(v)), lp);
      _drawLabel(canvas, label, rect.left - 28, yOf(v) - 7, size: 9, color: c);
    }

    // خط روند
    final lp = Paint()
      ..color = AppColors.navyBlue
      ..strokeWidth = 1.8;
    for (var i = 0; i < data.length - 1; i++) {
      canvas.drawLine(Offset(xOf(i), yOf(data[i])),
          Offset(xOf(i + 1), yOf(data[i + 1])), lp);
    }
    // نقاط
    for (var i = 0; i < data.length; i++) {
      canvas.drawCircle(Offset(xOf(i), yOf(data[i])),
          ooc.contains(i) ? 5 : 3,
          Paint()..color = ooc.contains(i) ? AppColors.level3 : AppColors.navyBlue);
    }
    if (ooc.isNotEmpty) {
      _drawLabel(canvas, 'نقاط خارج از کنترل: ${ooc.length}', rect.left, size.height - 18,
          color: AppColors.level3);
    }
  }

  @override
  bool shouldRepaint(covariant ControlReportPainter o) => true;
}

/// پراکندگی با ضریب همبستگی پیرسون
class ScatterReportPainter extends CustomPainter {
  ScatterReportPainter({required this.x, required this.y});

  final List<double> x, y;

  @override
  void paint(Canvas canvas, Size size) {
    final top = _drawTitle(canvas, 'نمودار پراکندگی (X در برابر Y)', size);
    final n = x.length < y.length ? x.length : y.length;
    if (n < 2) return;
    final rect = Rect.fromLTRB(50, top + 8, size.width - 30, size.height - 20);

    final xMin = x.reduce((a, b) => a < b ? a : b);
    final xMax = x.reduce((a, b) => a > b ? a : b);
    final yMin = y.reduce((a, b) => a < b ? a : b);
    final yMax = y.reduce((a, b) => a > b ? a : b);
    final sx = (xMax - xMin) == 0 ? 1.0 : (xMax - xMin);
    final sy = (yMax - yMin) == 0 ? 1.0 : (yMax - yMin);
    double px(double v) => rect.left + (v - xMin) / sx * rect.width;
    double py(double v) => rect.bottom - (v - yMin) / sy * rect.height;

    // محورها
    final ax = Paint()..color = const Color(0xFF94A3B8);
    canvas.drawLine(Offset(rect.left, rect.top), Offset(rect.left, rect.bottom), ax);
    canvas.drawLine(Offset(rect.left, rect.bottom), Offset(rect.right, rect.bottom), ax);

    // خط بهترین برازش (رگرسیون ساده) برای نمایش جهت رابطه
    final mx = Stats.mean(x), my = Stats.mean(y);
    var num = 0.0, den = 0.0;
    for (var i = 0; i < n; i++) {
      num += (x[i] - mx) * (y[i] - my);
      den += (x[i] - mx) * (x[i] - mx);
    }
    if (den > 0) {
      final slope = num / den;
      final reg = Paint()
        ..color = AppColors.orange
        ..strokeWidth = 2;
      canvas.drawLine(Offset(px(xMin), py(my + slope * (xMin - mx))),
          Offset(px(xMax), py(my + slope * (xMax - mx))), reg);
    }

    for (var i = 0; i < n; i++) {
      canvas.drawCircle(Offset(px(x[i]), py(y[i])), 4,
          Paint()..color = AppColors.navyBlue.withValues(alpha: .8));
    }
    final r = Stats.correlation(x, y);
    _drawLabel(canvas, 'ضریب همبستگی پیرسون: R = ${r.toStringAsFixed(3)}',
        rect.left, size.height - 16, color: AppColors.navyBlue);
  }

  @override
  bool shouldRepaint(covariant ScatterReportPainter o) => true;
}

/// جعبه‌ای — چارک‌ها، سبیلک‌ها و پرت‌های ۱٫۵×IQR
class BoxReportPainter extends CustomPainter {
  BoxReportPainter({required this.data});

  final List<double> data;

  @override
  void paint(Canvas canvas, Size size) {
    final top = _drawTitle(canvas, 'نمودار جعبه‌ای (چارک‌ها و پرت‌ها)', size);
    if (data.length < 4) return;
    final s = Stats.sorted(data);
    final (q1: q1, q3: q3) = Stats.quartiles(data);
    final med = Stats.median(data);
    final iqr = q3 - q1;
    final loW = s.firstWhere((v) => v >= q1 - 1.5 * iqr);
    final hiW = s.lastWhere((v) => v <= q3 + 1.5 * iqr);
    final outs = Stats.outliers(data);

    final rect = Rect.fromLTRB(60, top + 30, size.width - 40, size.height - 30);
    final min = s.first, max = s.last;
    final span = (max - min) == 0 ? 1.0 : (max - min);
    double xOf(double v) => rect.left + (v - min) / span * rect.width;
    final cy = rect.top + rect.height / 2;
    final bh = rect.height * 0.42;

    final box = Paint()
      ..color = AppColors.navyBlue.withValues(alpha: .2)
      ..style = PaintingStyle.fill;
    final line = Paint()
      ..color = AppColors.navyBlue
      ..strokeWidth = 2;

    canvas.drawLine(Offset(xOf(loW), cy), Offset(xOf(q1), cy), line);
    canvas.drawLine(Offset(xOf(q3), cy), Offset(xOf(hiW), cy), line);
    canvas.drawLine(Offset(xOf(loW), cy - bh / 3), Offset(xOf(loW), cy + bh / 3), line);
    canvas.drawLine(Offset(xOf(hiW), cy - bh / 3), Offset(xOf(hiW), cy + bh / 3), line);
    canvas.drawRect(Rect.fromLTRB(xOf(q1), cy - bh / 2, xOf(q3), cy + bh / 2), box);
    canvas.drawRect(Rect.fromLTRB(xOf(q1), cy - bh / 2, xOf(q3), cy + bh / 2), line);
    canvas.drawLine(Offset(xOf(med), cy - bh / 2), Offset(xOf(med), cy + bh / 2),
        Paint()..color = AppColors.orange..strokeWidth = 3);

    for (final o in outs) {
      canvas.drawCircle(Offset(xOf(o), cy), 5,
          Paint()
            ..color = AppColors.level3
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2);
    }

    _drawLabel(canvas, 'Q1: ${q1.toStringAsFixed(1)}', xOf(q1) - 20, cy + bh / 2 + 12);
    _drawLabel(canvas, 'میانه: ${med.toStringAsFixed(1)}', xOf(med) - 24, cy - bh / 2 - 20);
    _drawLabel(canvas, 'Q3: ${q3.toStringAsFixed(1)}', xOf(q3) - 20, cy + bh / 2 + 12);
    _drawLabel(canvas, 'پرت‌ها: ${outs.length}', rect.left, rect.top - 24,
        color: AppColors.level3);
  }

  @override
  bool shouldRepaint(covariant BoxReportPainter o) => true;
}
