import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../core/utils/persian_utils.dart';
import '../core/utils/statistics.dart';
import '../data/models/level3_models.dart';
import '../features/level2/widgets/fishbone_widget.dart';
import '../features/level3/level3_state.dart';
import 'chart_image_renderer.dart';
import 'docx/docx_builder.dart';
import 'downloads_resolver.dart';
import 'report_painters_l3.dart';

/// گزارش جامع ۲۰ تا ۵۰ صفحه‌ای سطح ۳ (۸D / DMAIC / A3 / KT / RCA) —
/// شامل جلد با لوگو، فهرست، تمام نمودارها به‌صورت تصویر باکیفیت،
/// جداول FMEA و Pugh و COPQ و امضاهای نهایی.
class WordReportL3 {
  /// ساخت گزارش و ذخیره در پوشه‌ی دانلود؛ مسیر فایل را برمی‌گرداند.
  Future<String> generate({required Level3State state}) async {
    final bytes = await WordReportL3.build(state);
    final dir = await resolveDownloadsDir();
    final path =
        p.join(dir.path, 'GerehGosha-L3-Report-${state.problemId ?? 0}.docx');
    await File(path).writeAsBytes(bytes, flush: true);
    return path;
  }

  static Future<Uint8List> build(Level3State state) async {
    final doc = DocxBuilder();
    final fa = PersianUtils.faDigits;

    // ═══ جلد ═══
    doc.empty();
    doc.empty();
    try {
      final logo = await ChartImageRenderer.renderLogoPng(size: 180);
      doc.image(logo, widthCm: 4.5, heightCm: 4.5);
    } catch (_) {}
    doc.para('گزارش حل مسئله‌ی سطح ۳ — گره‌گشا',
        bold: true, size: 52, center: true, color: '1E3A8A');
    doc.para('«گسترده و بحرانی» • ${state.methodology.label}',
        bold: true, size: 30, center: true, color: 'F97316');
    doc.empty();
    doc.para(state.title, bold: true, size: 34, center: true);
    doc.empty();
    doc.labelValue('تهیه‌کننده', 'حسین بختیاری');
    doc.labelValue('تاریخ گزارش', fa(DateTime.now().toIso8601String().substring(0, 10)));
    doc.labelValue('وضعیت', state.managerApproval ? 'تایید مدیریت شده ✓' : 'در حال تکمیل');
    doc.pageBreak();

    // ═══ فهرست ═══
    doc.heading('فهرست مطالب');
    const toc = [
      '۱. خلاصه‌ی اجرایی', '۲. تعریف مسئله و تیم پروژه',
      '۳. اقدامات مهار (Containment)', '۴. تحلیل آماری پیشرفته',
      '۵. تحلیل حالت‌های خرابی (FMEA)', '۶. تحلیل ریشه‌ای جامع',
      '۷. طراحی و انتخاب راه‌حل (Pugh)', '۸. اجرای آزمایشی (Pilot)',
      '۹. هزینه‌ی کیفیت و بازگشت سرمایه', '۱۰. پیاده‌سازی و آموزش',
      '۱۱. استانداردسازی و مستندات', '۱۲. درس‌آموخته‌ها و بانک دانش',
      '۱۳. جمع‌بندی و امضاها',
    ];
    for (final t in toc) {
      doc.para(t, size: 24);
    }
    doc.pageBreak();

    // ═══ ۱. خلاصه‌ی اجرایی ═══
    doc.heading('۱. خلاصه‌ی اجرایی');
    doc.labelValue('پروژه', state.title);
    doc.labelValue('متدولوژی', state.methodology.label);
    doc.labelValue('سطح', '۳ — گسترده و بحرانی');
    doc.labelValue('اعضای تیم', fa('${state.team.length}'));
    doc.labelValue('صرفه‌جویی سالانه', fa('${state.savings.toStringAsFixed(0)} ریال'));
    doc.labelValue('بازگشت سرمایه (ROI)', fa('${state.roi.toStringAsFixed(0)}٪'));
    doc.pageBreak();

    // ═══ ۲. تعریف مسئله + تیم ═══
    doc.heading('۲. تعریف مسئله و تیم پروژه');
    final d = state.def;
    doc.labelValue('چیستی (What)', d.what);
    doc.labelValue('چرا (Why)', d.why);
    doc.labelValue('چه کسی (Who)', d.who);
    doc.labelValue('کجا (Where)', d.where);
    doc.labelValue('چه زمانی (When)', d.when);
    doc.labelValue('چطور (How)', d.how);
    doc.labelValue('چقدر (How Much)', d.howMuch);
    doc.labelValue('درجه بحرانیت', fa('${state.criticality}') + ' از ۵');
    if (state.team.isNotEmpty) {
      doc.table([
        ['نام', 'نقش'],
        for (final t in state.team)
          [t.name, TeamRoleL3.fa[t.role] ?? t.role],
      ]);
    }
    if (state.kpis.isNotEmpty) {
      doc.para('شاخص‌های کلیدی پایه:', bold: true);
      doc.table([
        ['شاخص', 'مقدار فعلی', 'واحد'],
        for (final k in state.kpis)
          [k.name, fa((k.baseline ?? 0).toStringAsFixed(2)), k.unit],
      ]);
    }
    doc.pageBreak();

    // ═══ ۳. Containment ═══
    doc.heading('۳. اقدامات مهار (Containment)');
    if (state.containment.isEmpty) {
      doc.para('اقدامی ثبت نشده است.');
    } else {
      doc.table([
        ['اقدام', 'شروع', 'پایان', 'تایید مدیر'],
        for (final c in state.containment)
          [
            c.title,
            c.start?.toIso8601String().substring(0, 10) ?? '—',
            c.end?.toIso8601String().substring(0, 10) ?? '—',
            c.approved ? '✓ تایید' : 'در انتظار',
          ],
      ]);
      doc.labelValue('وضعیت نهایی',
          state.containmentApproved ? 'تایید اثربخشی توسط مدیر ✓' : 'در انتظار تایید');
    }
    doc.pageBreak();

    // ═══ ۴. آمار ═══
    doc.heading('۴. تحلیل آماری پیشرفته');
    final hist = state.stats['histogram'];
    if (hist != null && hist.values.isNotEmpty) {
      final png = await ChartImageRenderer.renderPainterPng(
          HistogramReportPainter(data: hist.values, lsl: state.lsl, usl: state.usl),
          760, 300);
      doc.image(png);
    }
    final ctl = state.stats['control'];
    if (ctl != null && ctl.values.length > 1) {
      final png = await ChartImageRenderer.renderPainterPng(
          ControlReportPainter(data: ctl.values), 760, 300);
      doc.image(png);
    }
    final scat = state.stats['scatter'];
    if (scat != null && scat.values.isNotEmpty && scat.values2.isNotEmpty) {
      final png = await ChartImageRenderer.renderPainterPng(
          ScatterReportPainter(x: scat.values, y: scat.values2), 760, 300);
      doc.image(png);
    }
    final box = state.stats['box'];
    if (box != null && box.values.length > 3) {
      final png = await ChartImageRenderer.renderPainterPng(
          BoxReportPainter(data: box.values), 760, 260);
      doc.image(png);
    }
    doc.pageBreak();

    // ═══ ۵. FMEA ═══
    doc.heading('۵. تحلیل حالت‌های خرابی (FMEA)');
    if (state.fmea.isEmpty) {
      doc.para('سطری ثبت نشده است.');
    } else {
      doc.table([
        ['آیتم', 'حالت خرابی', 'اثر', 'S', 'علت', 'O', 'کنترل', 'D', 'RPN'],
        for (final f in state.fmea)
          [
            f.itemName, f.failureMode, f.effect, fa('${f.severity}'),
            f.cause, fa('${f.occurrence}'), f.control, fa('${f.detection}'),
            fa('${f.rpn}'),
          ],
      ]);
      doc.para('حالات بحرانی (RPN≥۱۰۰): '
          '${state.fmea.where((f) => f.isCritical).map((f) => f.failureMode).join('، ')}',
          bold: true, color: 'DC2626');
    }
    doc.pageBreak();

    // ═══ ۶. RCA ═══
    doc.heading('۶. تحلیل ریشه‌ای جامع');
    if (state.fishbone.isNotEmpty) {
      final png = await ChartImageRenderer.renderPainterPng(
          FishbonePainter(nodes: state.fishbone, problemTitle: state.title),
          780, 380);
      doc.image(png, heightCm: 10);
    }
    final leafWhys = state.whysTree
        .where((w) => !state.whysTree.any((x) => x.parentId == w.nodeId))
        .toList();
    if (leafWhys.isNotEmpty) {
      doc.para('ریشه‌های نهایی شناسایی‌شده با چراهای پنج‌گانه:', bold: true);
      for (final w in leafWhys) {
        doc.para('• ${w.text}');
      }
    }
    final kt = state.kt;
    if (kt.isWhat.isNotEmpty || kt.isWhen.isNotEmpty) {
      doc.para('تحلیل KT (هست / نیست):', bold: true);
      doc.table([
        ['بُعد', 'هست', 'نیست'],
        ['چه چیزی', kt.isWhat, kt.isNotWhat],
        ['کجا', kt.isWhere, kt.isNotWhere],
        ['چه زمانی', kt.isWhen, kt.isNotWhen],
        ['چه کسی', kt.isWho, kt.isNotWho],
      ]);
    }
    doc.pageBreak();

    // ═══ ۷. راه‌حل + Pugh ═══
    doc.heading('۷. طراحی و انتخاب راه‌حل');
    doc.para('ایده‌های طوفان فکری: ${state.ideas.join('، ')}');
    if (state.pughSolutions.isNotEmpty) {
      final totals = state.pughTotals();
      doc.table([
        ['راه‌حل', 'مجموع وزنی', 'رتبه'],
        ...(() {
          final sorted = totals.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));
          return [
            for (var i = 0; i < sorted.length; i++)
              [sorted[i].key, fa('${sorted[i].value}'),
                i == 0 ? '🏆 برتر' : fa('${i + 1}')],
          ];
        })(),
      ]);
      doc.labelValue('راه‌حل مصوب', state.bestPughSolution ?? '—');
    }
    if (state.risks.isNotEmpty) {
      doc.para('ریسک‌های راه‌حل مصوب:', bold: true);
      doc.table([
        ['ریسک', 'امتیاز', 'راه‌حل کاهشی'],
        for (final r in state.risks)
          [r['risk'] as String, fa('${r['score']}'), (r['mitigation'] as String?) ?? ''],
      ]);
    }
    doc.pageBreak();

    // ═══ ۸. Pilot ═══
    doc.heading('۸. اجرای آزمایشی (Pilot)');
    if (state.pilots.isEmpty) {
      doc.para('پایلوتی ثبت نشده است.');
    } else {
      doc.table([
        ['تاریخ', 'قبل', 'بعد', 'یادداشت'],
        for (final p in state.pilots)
          [p.date.toIso8601String().substring(0, 10), fa(p.before.toStringAsFixed(2)),
            fa(p.after.toStringAsFixed(2)), p.statNote ?? ''],
      ]);
      final w = Stats.welchT(
          state.pilots.map((p) => p.before).toList(),
          state.pilots.map((p) => p.after).toList());
      doc.para('آزمون معناداری: t = ${fa(w.t.toStringAsFixed(2))} — '
          '${w.significant || w.t.abs() >= 2 ? 'تفاوت معنادار است ✓' : 'تفاوت معنادار نیست'}',
          bold: true);
    }
    doc.pageBreak();

    // ═══ ۹. COPQ ═══
    doc.heading('۹. هزینه‌ی کیفیت و بازگشت سرمایه');
    doc.table([
      ['دسته‌بندی', 'قبل', 'بعد', 'صرفه‌جویی'],
      for (final c in state.copq)
        [c.faCategory, fa(c.before.toStringAsFixed(0)),
          fa(c.after.toStringAsFixed(0)), fa((c.before - c.after).toStringAsFixed(0))],
      ['جمع', fa(state.copqBefore.toStringAsFixed(0)),
        fa(state.copqAfter.toStringAsFixed(0)), fa(state.savings.toStringAsFixed(0))],
    ]);
    doc.labelValue('سرمایه‌گذاری', fa('${state.investment.toStringAsFixed(0)} ریال'));
    doc.labelValue('ROI', fa('${state.roi.toStringAsFixed(0)}٪'));
    doc.labelValue('تایید مالی', state.financeApproval ? '✓' : '—');
    doc.pageBreak();

    // ═══ ۱۰. پیاده‌سازی و آموزش ═══
    doc.heading('۱۰. پیاده‌سازی کامل و آموزش');
    if (state.trainings.isNotEmpty) {
      doc.table([
        ['موضوع آموزش', 'مدرس', 'شرکت‌کننده', 'تاریخ'],
        for (final t in state.trainings)
          [t['topic'] as String? ?? '', t['trainer'] as String? ?? '',
            t['attendee'] as String? ?? '', t['date'] as String? ?? ''],
      ]);
    }
    if (state.resources.isNotEmpty) {
      doc.table([
        ['نوع منبع', 'شرح', 'مقدار'],
        for (final r in state.resources)
          [r['type'] as String? ?? '', r['desc'] as String? ?? '',
            fa('${r['amount'] ?? ''}')],
      ]);
    }
    doc.pageBreak();

    // ═══ ۱۱. استانداردسازی ═══
    doc.heading('۱۱. استانداردسازی و مستندات');
    doc.para('دستورالعمل استاندارد (SOP):', bold: true);
    doc.para(state.sopText.isEmpty ? '—' : state.sopText);
    if (state.sopReviewDate != null) {
      doc.labelValue('تاریخ بازنگری بعدی',
          fa(state.sopReviewDate!.toIso8601String().substring(0, 10)));
    }
    if (state.updatedDocs.isNotEmpty) {
      doc.labelValue('مستندات به‌روزشده', state.updatedDocs.join('، '));
    }
    doc.pageBreak();

    // ═══ ۱۲. درس‌آموخته‌ها ═══
    doc.heading('۱۲. درس‌آموخته‌ها و بانک دانش');
    for (final l in state.lessons) {
      doc.para('• (${l.categoryFa}) ${l.lesson}');
    }
    doc.para('این موارد به‌صورت خودکار به بانک دانش گره‌گشا منتقل می‌شوند.',
        size: 20, color: '64748B');
    doc.pageBreak();

    // ═══ ۱۳. جمع‌بندی و امضا ═══
    doc.heading('۱۳. جمع‌بندی و امضاها');
    doc.para('پروژه «${state.title}» با متدولوژی ${state.methodology.label} به پایان رسید؛ '
        'مجموع صرفه‌جویی ${fa(state.savings.toStringAsFixed(0))} ریال با بازگشت سرمایه '
        '${fa(state.roi.toStringAsFixed(0))}٪ حاصل شد.');
    doc.empty();
    doc.table([
      ['نقش', 'نام', 'امضا'],
      ['رهبر تیم', state.team.where((t) => t.role == 'leader').isEmpty
          ? '' : state.team.firstWhere((t) => t.role == 'leader').name, ''],
      ['مدیر کیفیت', '', ''],
      ['مدیر مالی', state.financeApproval ? 'تایید شده' : '', ''],
      ['مدیر حامی', state.sponsorApproval ? 'تایید شده' : '', ''],
      ['تهیه‌کننده', 'حسین بختیاری', ''],
    ]);

    return doc.build();
  }
}
