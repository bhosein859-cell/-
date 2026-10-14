import 'dart:io';

import 'package:excel/excel.dart' as xl;
import 'package:path/path.dart' as p;

import '../core/utils/persian_utils.dart';
import '../data/models/gantt_task.dart';
import '../features/level2/level2_state.dart';
import 'downloads_resolver.dart';

/// خروجی Excel (.xlsx) چهارشیته برای مسئله‌ی سطح ۲ — کاملاً آفلاین
/// با پکیج خالص Dart یعنی `excel`.
class ExcelExporter {
  Future<String> exportLevel2({required Level2State state}) async {
    final wb = xl.Excel.createExcel();
    wb.delete('Sheet1');

    // ── شیت ۱: جدول اقدامات (Action Plan 5W2H) ──
    final s1 = wb['Action Plan'];
    s1.appendRow([
      xl.TextCellValue('چه کاری؟ (What)'),
      xl.TextCellValue('چه کسی؟ (Who)'),
      xl.TextCellValue('کجا؟ (Where)'),
      xl.TextCellValue('چرا؟ (Why)'),
      xl.TextCellValue('چگونه؟ (How)'),
      xl.TextCellValue('چقدر؟ (How Much)'),
      xl.TextCellValue('وضعیت'),
      xl.TextCellValue('پیشرفت (٪)'),
    ]);
    for (final a in state.actions) {
      s1.appendRow([
        xl.TextCellValue(a.metadata['what']?.toString() ?? a.title),
        xl.TextCellValue(a.metadata['who']?.toString() ?? ''),
        xl.TextCellValue(a.metadata['where']?.toString() ?? ''),
        xl.TextCellValue(a.metadata['why']?.toString() ?? ''),
        xl.TextCellValue(a.metadata['how']?.toString() ?? ''),
        xl.TextCellValue(a.metadata['how_much']?.toString() ?? ''),
        xl.TextCellValue(a.statusFa),
        xl.IntCellValue(a.progress),
      ]);
    }

    // ── شیت ۲: داده‌های پارتو ──
    final s2 = wb['Pareto'];
    s2.appendRow([
      xl.TextCellValue('رتبه'),
      xl.TextCellValue('علت'),
      xl.TextCellValue('فراوانی'),
      xl.TextCellValue('درصد تجمعی'),
    ]);
    for (var i = 0; i < state.pareto.length; i++) {
      s2.appendRow([
        xl.IntCellValue(i + 1),
        xl.TextCellValue(state.pareto[i].cause),
        xl.DoubleCellValue(state.pareto[i].frequency),
        xl.DoubleCellValue(
            double.parse(state.pareto[i].cumulativePercent.toStringAsFixed(1))),
      ]);
    }

    // ── شیت ۳: داده‌های گانت چارت ──
    final s3 = wb['Gantt'];
    s3.appendRow([
      xl.TextCellValue('اقدام'),
      xl.TextCellValue('تاریخ شروع'),
      xl.TextCellValue('تاریخ پایان'),
      xl.TextCellValue('وضعیت'),
      xl.TextCellValue('پیشرفت (٪)'),
      xl.TextCellValue('وابسته به'),
    ]);
    for (final t in state.gantt) {
      s3.appendRow([
        xl.TextCellValue(t.title),
        xl.TextCellValue(PersianUtils.faDate(t.startDate)),
        xl.TextCellValue(PersianUtils.faDate(t.endDate)),
        xl.TextCellValue(GanttStatus.faLabels[t.status] ?? t.status),
        xl.IntCellValue(t.progress),
        xl.TextCellValue(t.dependsOn?.toString() ?? ''),
      ]);
    }

    // ── شیت ۴: شاخص‌های قبل و بعد ──
    final s4 = wb['KPI Before-After'];
    s4.appendRow([
      xl.TextCellValue('شاخص'),
      xl.TextCellValue('واحد'),
      xl.TextCellValue('قبل از اقدام'),
      xl.TextCellValue('هدف'),
      xl.TextCellValue('بعد از اقدام'),
      xl.TextCellValue('درصد بهبود'),
    ]);
    for (final k in state.kpis) {
      s4.appendRow([
        xl.TextCellValue(k.name),
        xl.TextCellValue(k.unit),
        k.baseline != null
            ? xl.DoubleCellValue(k.baseline!)
            : xl.TextCellValue(''),
        k.target != null ? xl.DoubleCellValue(k.target!) : xl.TextCellValue(''),
        k.after != null ? xl.DoubleCellValue(k.after!) : xl.TextCellValue(''),
        k.improvementPercent != null
            ? xl.DoubleCellValue(
                double.parse(k.improvementPercent!.toStringAsFixed(1)))
            : xl.TextCellValue(''),
      ]);
    }

    final bytes = wb.save();
    if (bytes == null) throw StateError('خطا در ساخت فایل Excel');

    final dir = await resolveDownloadsDir();
    final path = p.join(dir.path, 'GerehGosha-L2-Data-${state.problemId ?? 0}.xlsx');
    await File(path).writeAsBytes(bytes, flush: true);
    return path;
  }
}
