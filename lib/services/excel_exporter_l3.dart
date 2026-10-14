import 'dart:io';

import 'package:excel/excel.dart' as xl;
import 'package:path/path.dart' as p;

import '../core/utils/statistics.dart';
import '../features/level3/level3_state.dart';
import 'downloads_resolver.dart';

/// خروجی Excel (.xlsx) پنج‌شیته برای پروژه‌ی سطح ۳:
/// داده خام آماری، FMEA، ماتریس Pugh، COPQ و اقدامات اصلاحی.
class ExcelExporterL3 {
  Future<String> exportLevel3({required Level3State state}) async {
    final wb = xl.Excel.createExcel();
    wb.delete('Sheet1');

    // ── شیت ۱: داده خام آماری + آمار محاسبه‌شده ──
    final s1 = wb['Stat Data'];
    s1.appendRow([
      xl.TextCellValue('نوع نمودار'),
      xl.TextCellValue('مقدار'),
      xl.TextCellValue('مقدار دوم (Y)'),
    ]);
    for (final e in state.stats.entries) {
      final v = e.value.values;
      final v2 = e.value.values2;
      final n = v.length > v2.length ? v.length : v2.length;
      for (var i = 0; i < n; i++) {
        s1.appendRow([
          xl.TextCellValue(e.key),
          i < v.length ? xl.DoubleCellValue(v[i]) : xl.TextCellValue(''),
          i < v2.length ? xl.DoubleCellValue(v2[i]) : xl.TextCellValue(''),
        ]);
      }
      if (v.isNotEmpty) {
        s1.appendRow([
          xl.TextCellValue('${e.key} — میانگین'),
          xl.DoubleCellValue(Stats.mean(v)),
          xl.TextCellValue(''),
        ]);
        s1.appendRow([
          xl.TextCellValue('${e.key} — انحراف معیار'),
          xl.DoubleCellValue(Stats.stddev(v)),
          xl.TextCellValue(''),
        ]);
      }
    }

    // ── شیت ۲: FMEA ──
    final s2 = wb['FMEA'];
    s2.appendRow([
      xl.TextCellValue('آیتم'),
      xl.TextCellValue('حالت خرابی'),
      xl.TextCellValue('اثر'),
      xl.TextCellValue('S'),
      xl.TextCellValue('علت'),
      xl.TextCellValue('O'),
      xl.TextCellValue('کنترل'),
      xl.TextCellValue('D'),
      xl.TextCellValue('RPN'),
      xl.TextCellValue('بحرانی'),
      xl.TextCellValue('اقدام پیشنهادی'),
    ]);
    for (final f in state.fmea) {
      s2.appendRow([
        xl.TextCellValue(f.itemName),
        xl.TextCellValue(f.failureMode),
        xl.TextCellValue(f.effect),
        xl.IntCellValue(f.severity),
        xl.TextCellValue(f.cause),
        xl.IntCellValue(f.occurrence),
        xl.TextCellValue(f.control),
        xl.IntCellValue(f.detection),
        xl.IntCellValue(f.rpn),
        xl.TextCellValue(f.isCritical ? 'بله' : 'خیر'),
        xl.TextCellValue(f.proposedAction ?? ''),
      ]);
    }

    // ── شیت ۳: ماتریس Pugh ──
    final s3 = wb['Pugh Matrix'];
    final totals = state.pughTotals();
    s3.appendRow([
      xl.TextCellValue('راه‌حل'),
      xl.TextCellValue('مجموع وزنی'),
      xl.TextCellValue('رتبه'),
    ]);
    final sorted = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    for (var i = 0; i < sorted.length; i++) {
      s3.appendRow([
        xl.TextCellValue(sorted[i].key),
        xl.IntCellValue(sorted[i].value),
        xl.IntCellValue(i + 1),
      ]);
    }

    // ── شیت ۴: COPQ ──
    final s4 = wb['COPQ'];
    s4.appendRow([
      xl.TextCellValue('دسته‌بندی'),
      xl.TextCellValue('قبل'),
      xl.TextCellValue('بعد'),
      xl.TextCellValue('صرفه‌جویی'),
    ]);
    for (final c in state.copq) {
      s4.appendRow([
        xl.TextCellValue(c.faCategory),
        xl.DoubleCellValue(c.before),
        xl.DoubleCellValue(c.after),
        xl.DoubleCellValue(c.before - c.after),
      ]);
    }
    s4.appendRow([
      xl.TextCellValue('جمع'),
      xl.DoubleCellValue(state.copqBefore),
      xl.DoubleCellValue(state.copqAfter),
      xl.DoubleCellValue(state.savings),
    ]);
    s4.appendRow([xl.TextCellValue('ROI ٪'), xl.DoubleCellValue(state.roi), xl.TextCellValue(''), xl.TextCellValue('')]);

    // ── شیت ۵: اقدامات اصلاحی (از F بحرانی‌ها + مهار) ──
    final s5 = wb['Corrective Actions'];
    s5.appendRow([
      xl.TextCellValue('منبع'),
      xl.TextCellValue('اقدام'),
      xl.TextCellValue('وضعیت'),
    ]);
    for (final c in state.containment) {
      s5.appendRow([
        xl.TextCellValue('Containment'),
        xl.TextCellValue(c.title),
        xl.TextCellValue(c.approved ? 'تایید شده' : 'در انتظار'),
      ]);
    }
    for (final f in state.fmea.where((x) => x.isCritical)) {
      s5.appendRow([
        xl.TextCellValue('FMEA (RPN=${f.rpn})'),
        xl.TextCellValue(f.proposedAction ?? 'پیشنهاد نشده'),
        xl.TextCellValue(f.proposedAction != null ? 'ثبت شده' : 'باز'),
      ]);
    }

    final bytes = wb.save();
    if (bytes == null) throw StateError('خطا در ساخت فایل Excel');

    final dir = await resolveDownloadsDir();
    final path =
        p.join(dir.path, 'GerehGosha-L3-Data-${state.problemId ?? 0}.xlsx');
    await File(path).writeAsBytes(bytes, flush: true);
    return path;
  }
}
