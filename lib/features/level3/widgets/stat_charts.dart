import 'dart:io';

import 'package:excel/excel.dart' as xl;
import 'package:file_picker/file_picker.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/persian_utils.dart';
import '../../../core/utils/statistics.dart';
import '../level3_provider.dart';

/// پنل تحلیل آماری سطح ۳ — سبک Minitab/JMP اما ساده و راست‌چین:
/// هیستوگرام (با Cp/Cpk)، نمودار کنترل (UCL/LCL)، پراکندگی (R)، جعبه‌ای (پرت‌ها)
/// + ایمپورت داده از Excel + حالت تمام‌صفحه.
class StatAnalysisPanel extends ConsumerStatefulWidget {
  const StatAnalysisPanel({super.key});

  @override
  ConsumerState<StatAnalysisPanel> createState() => _StatAnalysisPanelState();
}

class _StatAnalysisPanelState extends ConsumerState<StatAnalysisPanel> {
  String _type = 'histogram';
  final _dataX = TextEditingController();
  final _dataY = TextEditingController();

  @override
  void dispose() {
    _dataX.dispose();
    _dataY.dispose();
    super.dispose();
  }

  List<double> get _values =>
      ref.read(level3WizardProvider).stats[_type]?.values ?? const [];

  List<double> get _values2 =>
      ref.read(level3WizardProvider).stats[_type]?.values2 ?? const [];

  Future<void> _save() async {
    await ref.read(level3WizardProvider.notifier).saveStat(
          _type,
          Stats.parseNumbers(_dataX.text),
          Stats.parseNumbers(_dataY.text),
        );
    setState(() {});
  }

  /// ایمپورت داده از فایل Excel (اولین شیت: ستون اول X، ستون دوم Y)
  Future<void> _importExcel() async {
    final picked = await FilePicker.platform.pickFiles(
      dialogTitle: 'ایمپورت داده از Excel',
      type: FileType.custom,
      allowedExtensions: const ['xlsx'],
    );
    if (picked == null || picked.files.single.path == null) return;
    try {
      final bytes = await File(picked.files.single.path!).readAsBytes();
      final wb = xl.Excel.decodeBytes(bytes);
      final sheet = wb.tables[wb.tables.keys.first]!;
      final xs = <double>[];
      final ys = <double>[];
      for (final row in sheet.rows.skip(1)) {
        final nums = <double>[];
        for (final cell in row) {
          // مقدار خام سلول از پوشش CellValue استخراج می‌شود
          final raw = cell?.value?.value;
          final d = raw is num
              ? raw.toDouble()
              : (raw is String ? double.tryParse(raw.trim()) : null);
          if (d != null) nums.add(d);
        }
        if (nums.isNotEmpty) xs.add(nums[0]);
        if (nums.length > 1) ys.add(nums[1]);
      }
      _dataX.text = xs.join(', ');
      _dataY.text = ys.join(', ');
      await ref
          .read(level3WizardProvider.notifier)
          .saveStat(_type, xs, ys);
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('خطا در خواندن Excel: $e')));
      }
    }
  }

  void _fullscreen(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog.fullscreen(
        child: Scaffold(
          appBar: AppBar(
            title: const Text('نمایش تمام‌صفحه'),
            leading: IconButton(
                icon: const Icon(Icons.fullscreen_exit),
                onPressed: () => Navigator.pop(ctx)),
          ),
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: _chart(context, big: true),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(level3WizardProvider);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'histogram', label: Text('هیستوگرام'), icon: Icon(Icons.bar_chart)),
                ButtonSegment(value: 'control', label: Text('کنترل'), icon: Icon(Icons.show_chart)),
                ButtonSegment(value: 'scatter', label: Text('پراکندگی'), icon: Icon(Icons.scatter_plot)),
                ButtonSegment(value: 'box', label: Text('جعبه‌ای'), icon: Icon(Icons.view_agenda_outlined)),
              ],
              selected: {_type},
              onSelectionChanged: (s) => setState(() => _type = s.first),
            ),
            IconButton.filledTonal(
              tooltip: 'تمام‌صفحه',
              icon: const Icon(Icons.fullscreen),
              onPressed: () => _fullscreen(context),
            ),
            OutlinedButton.icon(
              onPressed: _importExcel,
              icon: const Icon(Icons.file_upload_outlined),
              label: const Text('ایمپورت از Excel'),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // ورودی داده‌ها
        TextField(
          controller: _dataX,
          maxLines: 2,
          decoration: const InputDecoration(
              hintText: 'داده‌ها (با ویرگول یا فاصله): ۱۲٫۵, ۱۳, ۱۲٫۸ …'),
        ),
        if (_type == 'scatter') ...[
          const SizedBox(height: 8),
          TextField(
            controller: _dataY,
            maxLines: 2,
            decoration: const InputDecoration(hintText: 'مقادیر محور Y …'),
          ),
        ],
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          children: [
            FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.refresh),
                label: const Text('ثبت و رسم')),
            if (_type == 'histogram' || _type == 'control') ...[
              SizedBox(
                width: 110,
                child: TextField(
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'LSL'),
                  onChanged: (v) => ref.read(level3WizardProvider.notifier)
                      .saveLimits(double.tryParse(v) ?? state.lsl, state.usl),
                ),
              ),
              SizedBox(
                width: 110,
                child: TextField(
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'USL'),
                  onChanged: (v) => ref.read(level3WizardProvider.notifier)
                      .saveLimits(state.lsl, double.tryParse(v) ?? state.usl),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 16),

        SizedBox(height: 300, child: _chart(context)),
        const SizedBox(height: 8),
        _statsLine(theme),
      ],
    );
  }

  Widget _chart(BuildContext context, {bool big = false}) {
    final data = _values;
    switch (_type) {
      case 'control':
        return data.isEmpty ? _empty() : _controlChart(data);
      case 'scatter':
        return (_values.isEmpty || _values2.isEmpty)
            ? _empty()
            : _scatterChart(_values, _values2);
      case 'box':
        return data.isEmpty ? _empty() : _boxChart(data);
      default:
        return data.isEmpty ? _empty() : _histChart(data);
    }
  }

  Widget _empty() => const Center(
      child: Text('داده‌ای ثبت نشده؛ اعداد را وارد کنید یا از Excel ایمپورت کنید.'));

  Widget _histChart(List<double> data) {
    final bins = Stats.histogram(data);
    final maxC = bins.isEmpty ? 1.0 : bins.map((b) => b.count).reduce((a, b) => a > b ? a : b).toDouble();
    return BarChart(
      BarChartData(
        maxY: maxC * 1.2,
        barGroups: [
          for (var i = 0; i < bins.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: bins[i].count.toDouble(),
                  color: AppColors.navyBlue,
                  width: 24,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ],
            ),
        ],
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (g, gi, rod, ri) => BarTooltipItem(
              '${bins[g.x].label}\nتعداد: ${PersianUtils.faDigits('${bins[g.x].count}')}',
              const TextStyle(fontFamily: 'Vazirmatn', color: Colors.white, fontSize: 12),
            ),
          ),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, m) => Text(
                v.toInt() < bins.length ? bins[v.toInt()].label.split('–').first : '',
                style: const TextStyle(fontSize: 9),
              ),
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (v, m) =>
                  Text(PersianUtils.faDigits(v.toStringAsFixed(0)),
                      style: const TextStyle(fontSize: 10)),
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: false),
      ),
    );
  }

  Widget _controlChart(List<double> data) {
    final (cl: cl, ucl: ucl, lcl: lcl) = Stats.controlLimits(data);
    final ooc = Stats.outOfControlIndices(data).toSet();
    final maxY = (ucl > (data.isEmpty ? 0 : data.reduce((a, b) => a > b ? a : b))
            ? ucl
            : data.reduce((a, b) => a > b ? a : b)) +
        1;
    final minY = (lcl < (data.isEmpty ? 0 : data.reduce((a, b) => a < b ? a : b))
            ? lcl
            : data.reduce((a, b) => a < b ? a : b)) -
        1;
    return LineChart(
      LineChartData(
        minY: minY,
        maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            spots: [for (var i = 0; i < data.length; i++) FlSpot(i.toDouble(), data[i])],
            isCurved: false,
            color: AppColors.navyBlue,
            barWidth: 2,
            dotData: FlDotData(
              getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                radius: ooc.contains(index) ? 6 : 3.5,
                color: ooc.contains(index) ? AppColors.level3 : AppColors.navyBlue,
                strokeWidth: 1,
                strokeColor: Colors.white,
              ),
            ),
          ),
        ],
        extraLinesData: ExtraLinesData(horizontalLines: [
          HorizontalLine(y: ucl, color: AppColors.level3, strokeWidth: 1.5, dashArray: [6, 4],
              label: HorizontalLineLabel(text: 'UCL', style: const TextStyle(fontSize: 10, color: AppColors.level3))),
          HorizontalLine(y: cl, color: AppColors.success, strokeWidth: 1.5, dashArray: [6, 4],
              label: HorizontalLineLabel(text: 'CL', style: const TextStyle(fontSize: 10, color: AppColors.success))),
          HorizontalLine(y: lcl, color: AppColors.level3, strokeWidth: 1.5, dashArray: [6, 4],
              label: HorizontalLineLabel(text: 'LCL', style: const TextStyle(fontSize: 10, color: AppColors.level3))),
        ]),
        lineTouchData: LineTouchData(
          getTouchedSpotIndicator: (bar, spots) => [
            for (final s in spots)
              TouchedSpotIndicatorData(
                const FlLine(color: Colors.transparent),
                FlDotData(getDotPainter: (spot, p, b, i) => FlDotCirclePainter(
                    radius: 6, color: AppColors.orange, strokeWidth: 1, strokeColor: Colors.white)),
              ),
          ],
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (spots) => [
              for (final s in spots)
                LineTooltipItem(
                  'نمونه ${PersianUtils.faDigits('${s.x.toInt() + 1}')}: ${PersianUtils.faDigits(s.y.toStringAsFixed(2))}'
                  '${ooc.contains(s.x.toInt()) ? '\n⚠ خارج از کنترل' : ''}',
                  const TextStyle(fontFamily: 'Vazirmatn', color: Colors.white, fontSize: 12),
                ),
            ],
          ),
        ),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: false),
      ),
    );
  }

  Widget _scatterChart(List<double> x, List<double> y) {
    final n = x.length < y.length ? x.length : y.length;
    final r = Stats.correlation(x, y);
    return Stack(
      children: [
        ScatterChart(
          ScatterChartData(
            scatterSpots: [
              for (var i = 0; i < n; i++)
                ScatterSpot(x[i], y[i],
                    radius: 5, color: AppColors.navyBlue),
            ],
            scatterTouchData: ScatterTouchData(
              touchTooltipData: ScatterTouchTooltipData(
                getTooltipItems: (spot) => ScatterTooltipItem(
                  'X: ${PersianUtils.faDigits(spot.x.toStringAsFixed(2))}\nY: ${PersianUtils.faDigits(spot.y.toStringAsFixed(2))}',
                  textStyle: const TextStyle(fontFamily: 'Vazirmatn', color: Colors.white, fontSize: 12),
                ),
              ),
            ),
            titlesData: const FlTitlesData(show: false),
            borderData: FlBorderData(show: false),
            gridData: FlGridData(
              getDrawingHorizontalLine: (v) => BorderSide(color: AppColors.navyBlue.withValues(alpha: .1)),
              getDrawingVerticalLine: (v) => BorderSide(color: AppColors.navyBlue.withValues(alpha: .1)),
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.orange.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              'همبستگی R = ${PersianUtils.faDigits(r.toStringAsFixed(2))}'
              '${r.abs() > .7 ? ' (رابطه قوی)' : r.abs() > .4 ? ' (متوسط)' : ' (ضعیف)'}',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: AppColors.orange),
            ),
          ),
        ),
      ],
    );
  }

  Widget _boxChart(List<double> data) => CustomPaint(
        size: const Size(double.infinity, 300),
        painter: BoxPlotPainter(data: data),
      );

  Widget _statsLine(ThemeData theme) {
    final data = _values;
    if (data.isEmpty) return const SizedBox.shrink();
    final m = Stats.mean(data);
    final sd = Stats.stddev(data);
    final state = ref.read(level3WizardProvider);
    final cp = Stats.cp(lsl: state.lsl, usl: state.usl, sd: sd);
    final cpk = Stats.cpk(lsl: state.lsl, usl: state.usl, sd: sd, m: m);
    final ooc = Stats.outOfControlIndices(data).length;
    final outs = Stats.outliers(data).length;

    String text;
    switch (_type) {
      case 'control':
        text = 'میانگین: ${m.toStringAsFixed(2)} | انحراف معیار: ${sd.toStringAsFixed(2)} | نقاط خارج از کنترل: $ooc';
        break;
      case 'histogram':
        text = 'میانگین: ${m.toStringAsFixed(2)} | σ: ${sd.toStringAsFixed(2)} | Cp: ${cp.toStringAsFixed(2)} | Cpk: ${cpk.toStringAsFixed(2)}';
        break;
      case 'scatter':
        text = 'R: ${Stats.correlation(data, _values2).toStringAsFixed(2)}';
        break;
      default:
        text = 'میانه: ${Stats.median(data).toStringAsFixed(2)} | نقاط پرت: $outs';
    }
    return Text(
      PersianUtils.faDigits(text),
      style: theme.textTheme.bodySmall
          ?.copyWith(color: AppColors.navyBlue, fontWeight: FontWeight.w700),
    );
  }
}

/// نمودار جعبه‌ای سفارشی — چارک‌ها، سبیلک‌ها و نقاط پرت
class BoxPlotPainter extends CustomPainter {
  BoxPlotPainter({required this.data});

  final List<double> data;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    final s = Stats.sorted(data);
    final (q1: q1, q3: q3) = Stats.quartiles(data);
    final med = Stats.median(data);
    final iqr = q3 - q1;
    final loW = s.firstWhere((v) => v >= q1 - 1.5 * iqr);
    final hiW = s.lastWhere((v) => v <= q3 + 1.5 * iqr);
    final outs = Stats.outliers(data);

    final min = s.first;
    final max = s.last;
    final span = (max - min) == 0 ? 1.0 : (max - min);
    double x(double v) => 40 + (v - min) / span * (size.width - 80);

    final cy = size.height / 2;
    final bh = size.height * 0.34;

    final boxPaint = Paint()
      ..color = AppColors.navyBlue.withValues(alpha: .25)
      ..style = PaintingStyle.fill;
    final line = Paint()
      ..color = AppColors.navyBlue
      ..strokeWidth = 2;

    // سبیلک‌ها
    canvas.drawLine(Offset(x(loW), cy), Offset(x(q1), cy), line);
    canvas.drawLine(Offset(x(q3), cy), Offset(x(hiW), cy), line);
    canvas.drawLine(Offset(x(loW), cy - bh / 3), Offset(x(loW), cy + bh / 3), line);
    canvas.drawLine(Offset(x(hiW), cy - bh / 3), Offset(x(hiW), cy + bh / 3), line);

    // جعبه Q1..Q3
    canvas.drawRect(Rect.fromLTRB(x(q1), cy - bh / 2, x(q3), cy + bh / 2), boxPaint);
    canvas.drawRect(Rect.fromLTRB(x(q1), cy - bh / 2, x(q3), cy + bh / 2), line);

    // میانه
    canvas.drawLine(Offset(x(med), cy - bh / 2), Offset(x(med), cy + bh / 2),
        Paint()..color = AppColors.orange..strokeWidth = 3);

    // پرت‌ها
    for (final o in outs) {
      canvas.drawCircle(Offset(x(o), cy), 5,
          Paint()..color = AppColors.level3..style = PaintingStyle.stroke..strokeWidth = 2);
    }

    // برچسب‌ها
    for (final (v, label) in [(q1, 'Q1'), (med, 'میانه'), (q3, 'Q3')]) {
      final tp = TextPainter(
        text: TextSpan(
          text: '$label: ${v.toStringAsFixed(1)}',
          style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 11, color: Color(0xFF334155)),
        ),
        textDirection: TextDirection.rtl,
      )..layout();
      tp.paint(canvas, Offset(x(v) - tp.width / 2, cy + bh / 2 + 8));
    }
  }

  @override
  bool shouldRepaint(covariant BoxPlotPainter old) => old.data != data;
}
