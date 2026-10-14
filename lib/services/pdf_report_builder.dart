import 'dart:io';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path/path.dart' as p;

import '../core/theme/app_colors.dart';
import '../core/utils/persian_utils.dart';
import '../data/models/level3_models.dart';
import '../features/level3/level3_state.dart';
import 'chart_image_renderer.dart';
import 'downloads_resolver.dart';

/// گزارش بایگانی PDF سطح ۳ — هر صفحه با TextPainter روی بوم رندر می‌شود
/// تا متن فارسی با شکل‌دهی (shaping) صحیح ساخته شود؛ سپس به‌صورت تصویر
/// تمام‌صفحه در سند PDF جاسازی می‌گردد (کاملاً آفلاین).
class PdfReportBuilder {
  static const double _pageW = 794; // A4 @ 96dpi
  static const double _pageH = 1123;
  static const int _rowsPerPage = 24;

  /// ساخت و ذخیره؛ مسیر فایل را برمی‌گرداند.
  static Future<String> buildAndSave(Level3State state) async {
    final doc = pw.Document();
    for (final page in _pages(state)) {
      final chunks = _chunk(page.rows, _rowsPerPage);
      for (var i = 0; i < chunks.length; i++) {
        final png = await ChartImageRenderer.renderPainterPng(
          _PagePainter(
            title: page.title,
            rows: chunks[i],
            pageText: 'صفحه ${i + 1}/${chunks.length}',
            projectName: state.title,
          ),
          _pageW,
          _pageH,
          scale: 1.5,
        );
        doc.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            build: (_) => pw.Image(
              pw.MemoryImage(png),
              width: _pageW * 72 / 96,
              height: _pageH * 72 / 96,
              fit: pw.BoxFit.contain,
            ),
          ),
        );
      }
    }
    final dir = await resolveDownloadsDir();
    final path =
        p.join(dir.path, 'GerehGosha-L3-Report-${state.problemId ?? 0}.pdf');
    await File(path).writeAsBytes(await doc.save(), flush: true);
    return path;
  }

  // ── تولید محتوای صفحات از وضعیت پروژه ──
  static List<_PageContent> _pages(Level3State state) {
    final fa = PersianUtils.faDigits;
    final cover = _PageContent(title: 'گزارش پروژه', rows: [
      ('پروژه', state.title),
      ('متدولوژی', state.methodology.label),
      ('سطح', '۳ — گسترده و بحرانی'),
      ('اعضای تیم', fa('${state.team.length}')),
      ('تاریخ', fa(DateTime.now().toIso8601String().substring(0, 10))),
      ('تهیه‌کننده', 'حسین بختیاری'),
    ]);

    final problem = _PageContent(title: 'تعریف مسئله و تیم', rows: [
      ('چیستی', state.def.what),
      ('چرا', state.def.why),
      ('درجه بحرانیت', fa('${state.criticality}') + ' از ۵'),
      for (final t in state.team)
        ('عضو تیم', '${t.name} — ${TeamRoleL3.fa[t.role] ?? t.role}'),
      for (final k in state.kpis)
        ('شاخص پایه', '${k.name}: ${fa((k.baseline ?? 0).toStringAsFixed(2))} ${k.unit}'),
    ]);

    final containment = _PageContent(title: 'اقدامات مهار و آمار', rows: [
      for (final c in state.containment)
        ('مهار', '${c.title} — ${c.approved ? 'تایید شده' : 'در انتظار'}'),
      ('تایید مدیر', state.containmentApproved ? '✓' : '✗'),
      for (final e in state.stats.entries)
        ('داده آماری', '${e.key}: ${fa('${e.value.values.length}')} نمونه'),
      ('حدود', 'LSL: ${fa(state.lsl.toStringAsFixed(2))} | USL: ${fa(state.usl.toStringAsFixed(2))}'),
    ]);

    final fmea = _PageContent(title: 'تحلیل حالت‌های خرابی (FMEA)', rows: [
      for (final f in state.fmea)
        (f.itemName, '${f.failureMode} | علت: ${f.cause} | RPN=${fa('${f.rpn}')}'
            '${f.isCritical ? ' ⚠' : ''}'),
    ]);

    final rca = _PageContent(title: 'تحلیل ریشه‌ای', rows: [
      for (final w in state.whysTree
          .where((w) => !state.whysTree.any((x) => x.parentId == w.nodeId)))
        ('ریشه', w.text),
      if (state.kt.isWhat.isNotEmpty) ('KT — چه چیزی هست', state.kt.isWhat),
      if (state.kt.isWhen.isNotEmpty) ('KT — چه زمانی هست', state.kt.isWhen),
    ]);

    final totals = state.pughTotals();
    final solution = _PageContent(title: 'راه‌حل و ریسک‌ها', rows: [
      ('راه‌حل مصوب', state.bestPughSolution ?? '—'),
      for (final e in totals.entries)
        ('امتیاز راه‌حل', '${e.key}: ${fa('${e.value}')}'),
      for (final r in state.risks)
        ('ریسک', '${r['risk']} (امتیاز ${fa('${r['score']}')}) → ${r['mitigation']}'),
    ]);

    final pilot = _PageContent(title: 'پایلوت و هزینه‌ی کیفیت', rows: [
      for (final p in state.pilots)
        ('پایلوت ${p.date.toIso8601String().substring(0, 10)}',
            'قبل: ${fa(p.before.toStringAsFixed(2))} ← بعد: ${fa(p.after.toStringAsFixed(2))}'),
      for (final c in state.copq)
        ('COPQ — ${c.faCategory}',
            '${fa(c.before.toStringAsFixed(0))} ← ${fa(c.after.toStringAsFixed(0))}'),
      ('صرفه‌جویی', fa('${state.savings.toStringAsFixed(0)} ریال')),
      ('بازگشت سرمایه', fa('${state.roi.toStringAsFixed(0)}٪')),
    ]);

    final closure = _PageContent(title: 'درس‌آموخته‌ها و بستن پروژه', rows: [
      for (final l in state.lessons) ('${l.categoryFa}', l.lesson),
      ('تایید مالی', state.financeApproval ? '✓' : '✗'),
      ('تایید مدیر حامی', state.sponsorApproval ? '✓' : '✗'),
      ('امتیاز تیم', fa('${state.teamScore}')),
      ('تهیه‌کننده', 'حسین بختیاری'),
    ]);

    return [cover, problem, containment, fmea, rca, solution, pilot, closure];
  }

  static List<List<(String, String)>> _chunk(List<(String, String)> rows, int n) {
    if (rows.isEmpty) return [const []];
    final out = <List<(String, String)>>[];
    for (var i = 0; i < rows.length; i += n) {
      out.add(rows.sublist(i, i + n > rows.length ? rows.length : i + n));
    }
    return out;
  }
}

class _PageContent {
  const _PageContent({required this.title, required this.rows});
  final String title;
  final List<(String, String)> rows;
}

/// نقاش صفحه — پس‌زمینه، سربرگ برند، ردیف‌های برچسب/مقدار و پاصفحه
class _PagePainter extends CustomPainter {
  const _PagePainter({
    required this.title,
    required this.rows,
    required this.pageText,
    required this.projectName,
  });

  final String title;
  final List<(String, String)> rows;
  final String pageText;
  final String projectName;

  TextPainter _tp(String text, TextStyle style, {double maxWidth = 720}) =>
      TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: TextDirection.rtl,
        maxLines: 2,
        ellipsis: '…',
      )..layout(maxWidth: maxWidth);

  @override
  void paint(Canvas canvas, Size size) {
    // پس‌زمینه
    canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = const Color(0xFFFFFFFF));

    // نوار سربرگ برند
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, 10),
        Paint()..color = AppColors.navyBlue);
    canvas.drawRect(Rect.fromLTWH(0, 10, size.width, 4),
        Paint()..color = AppColors.orange);

    // عنوان صفحه
    final titleTp = _tp(title, const TextStyle(
        fontFamily: 'Vazirmatn', fontSize: 20, fontWeight: FontWeight.w900,
        color: AppColors.navyBlue));
    titleTp.paint(canvas, Offset(size.width - titleTp.width - 36, 30));

    final brandTp = _tp('گره‌گشا | حسین بختیاری', const TextStyle(
        fontFamily: 'Vazirmatn', fontSize: 11, color: Color(0xFF94A3B8)));
    brandTp.paint(canvas, const Offset(36, 38));

    // ردیف‌ها
    var y = 84.0;
    const labelStyle = TextStyle(
        fontFamily: 'Vazirmatn', fontSize: 13, fontWeight: FontWeight.w800,
        color: Color(0xFF334155));
    const valueStyle = TextStyle(
        fontFamily: 'Vazirmatn', fontSize: 12.5, color: Color(0xFF0F172A));

    for (final (label, value) in rows) {
      final labelTp = _tp(label, labelStyle, maxWidth: 200);
      final valueTp = _tp(value, valueStyle, maxWidth: 470);
      final rowH =
          (labelTp.height > valueTp.height ? labelTp.height : valueTp.height) + 14;

      // خط جداکننده
      canvas.drawLine(Offset(36, y + rowH - 6), Offset(size.width - 36, y + rowH - 6),
          Paint()
            ..color = const Color(0xFFE2E8F0)
            ..strokeWidth = 1);

      labelTp.paint(canvas, Offset(size.width - labelTp.width - 36, y));
      valueTp.paint(canvas, Offset(36, y));
      y += rowH;
    }

    // پاصفحه
    final footTp = _tp('$projectName — $pageText', const TextStyle(
        fontFamily: 'Vazirmatn', fontSize: 10, color: Color(0xFF94A3B8)));
    footTp.paint(
        canvas, Offset(size.width - footTp.width - 36, size.height - 30));
  }

  @override
  bool shouldRepaint(covariant _PagePainter old) => true;
}
