import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../core/constants/app_constants.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/persian_utils.dart';
import '../data/models/fishbone_node.dart';
import '../features/level2/level2_state.dart';
import '../features/level2/widgets/fishbone_widget.dart';
import '../features/level2/widgets/gantt_widget.dart';
import 'chart_image_renderer.dart';
import 'docx/docx_builder.dart';
import 'downloads_resolver.dart';

/// نقاش ساده‌ی پارتو مخصوص رندر گزارش (میله‌ها + خط تجمعی + آستانه ۸۰٪)
class ParetoReportPainter extends CustomPainter {
  ParetoReportPainter({required this.causes, required this.freqs, required this.cum});

  final List<String> causes;
  final List<double> freqs;
  final List<double> cum;

  @override
  void paint(Canvas canvas, Size size) {
    if (causes.isEmpty) return;
    final pad = 40.0;
    final plot = Rect.fromLTWH(pad, 20, size.width - pad * 2, size.height - 70);
    final maxF = math.max(1.0, freqs.reduce(math.max)) * 1.2;
    final bw = plot.width / causes.length;

    canvas.drawRect(plot, Paint()..color = const Color(0xFFF1F5F9));

    for (var i = 0; i < causes.length; i++) {
      final h = freqs[i] / maxF * plot.height;
      final rect = Rect.fromLTWH(plot.left + i * bw + bw * 0.2,
          plot.bottom - h, bw * 0.6, h);
      canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(4)),
          Paint()..color = cum[i] <= 80 ? AppColors.orange : AppColors.navyBlue.withValues(alpha: .5));

      final label = causes[i].length <= 10
          ? causes[i]
          : '${causes[i].substring(0, 10)}…';
      final tp = TextPainter(
        text: TextSpan(
            text: label,
            style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 10)),
        textDirection: TextDirection.rtl,
      )..layout(maxWidth: bw);
      tp.paint(canvas, Offset(plot.left + i * bw + bw / 2 - tp.width / 2, plot.bottom + 6));
    }

    // خط تجمعی
    final line = Path();
    for (var i = 0; i < causes.length; i++) {
      final pt = Offset(plot.left + i * bw + bw / 2,
          plot.bottom - (cum[i] / 100) * plot.height);
      if (i == 0) {
        line.moveTo(pt.dx, pt.dy);
      } else {
        line.lineTo(pt.dx, pt.dy);
      }
      canvas.drawCircle(pt, 4, Paint()..color = AppColors.level3);
    }
    canvas.drawPath(line, Paint()..color = AppColors.level3..strokeWidth = 2..style = PaintingStyle.stroke);

    // آستانه ۸۰٪
    final y80 = plot.bottom - 0.8 * plot.height;
    canvas.drawLine(Offset(plot.left, y80), Offset(plot.right, y80),
        Paint()..color = AppColors.level3.withValues(alpha: .6)..strokeWidth = 1.5);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

/// تولید گزارش Word چندصفحه‌ای (A3/PDCA) برای مسئله‌ی سطح ۲.
///
/// صفحات: عنوان (با لوگو و نام سازنده) → خلاصه مدیریتی → استخوان‌ماهی →
/// پارتو → درخت ۵ چرا → جدول 5W2H → گانت → بررسی و استانداردسازی.
class WordReportL2 {
  Future<String> generate({required Level2State state}) async {
    this.state = state;
    final doc = DocxBuilder();
    final now = DateTime.now();

    // ═══ صفحه ۱: عنوان ═══
    try {
      final logo = await ChartImageRenderer.renderLogoPng(size: 240);
      doc.image(logo, widthCm: 4.2, heightCm: 4.2);
    } catch (_) {
      // بدون لوگو هم گزارش معتبر است
    }
    doc.para('گزارش حل مسئله — سطح ۲ (متوسط و تیمی)', style: 'Title');
    doc.para(state.title, center: true, bold: true, size: 28, color: '1E3A8A');
    doc.empty();
    doc.para('نرم‌افزار: ${AppConstants.appName} | سازنده: ${AppConstants.creator}',
        center: true, size: 20, color: '555555');
    doc.para('تاریخ گزارش: ${PersianUtils.faDate(now)}', center: true, size: 20, color: '555555');
    doc.para('چارچوب: PDCA / A3', center: true, size: 20, color: '555555');
    doc.pageBreak();

    // ═══ صفحه ۲: خلاصه مدیریتی ═══
    doc.heading('۱) خلاصه مدیریتی (Executive Summary)');
    final rootCauses = state.fishbone.where((n) => n.isRootCause).length;
    final doneActions =
        state.actions.where((a) => a.progress >= 100).length;
    doc.para(
      'مسئله‌ی «${state.title}» در سطح ۲ (تیمی) با تیم ${state.team.length} نفره مورد تحلیل قرار گرفت. '
      'در مجموع ${state.fishbone.where((n) => !n.isCategory).length} علت احتمالی در نمودار استخوان‌ماهی شناسایی شد '
      'که ${rootCauses} مورد به‌عنوان ریشه‌ی اصلی علامت‌گذاری شدند. '
      'نمودار پارتو ${state.pareto.length} علت را اولویت‌بندی کرد و ${state.actions.length} اقدام اصلاحی تعریف شد '
      'که تاکنون $doneActions اقدام به‌طور کامل انجام شده است.',
    );
    doc.empty();
    doc.labelValue('تعریف مسئله (What)', state.def.what.isEmpty ? '—' : state.def.what);
    doc.labelValue('اهمیت (Why)', state.def.why.isEmpty ? '—' : state.def.why);
    doc.labelValue('محل (Where)', state.def.where.isEmpty ? '—' : state.def.where);
    doc.labelValue('زمان بروز (When)', state.def.when.isEmpty ? '—' : state.def.when);
    doc.labelValue('افراد درگیر (Who)', state.def.who.isEmpty ? '—' : state.def.who);
    doc.labelValue('شدت/هزینه (How Much)', state.def.howMuch.isEmpty ? '—' : state.def.howMuch);
    doc.empty();
    if (state.team.isNotEmpty) {
      doc.labelValue(
          'تیم حل مسئله',
          state.team
              .map((m) => '${m.name} (${m.role})')
              .join('، '));
    }
    doc.pageBreak();

    // ═══ صفحه ۳: استخوان‌ماهی ═══
    doc.heading('۲) تحلیل علل — نمودار استخوان‌ماهی (6M)');
    final fishPng = await ChartImageRenderer.renderPainterPng(
      FishbonePainter(nodes: state.fishbone, problemTitle: state.title),
      1150,
      470,
    );
    doc.image(fishPng, widthCm: 16.2, heightCm: 6.6);
    doc.empty();
    doc.table([
      ['دسته', 'علل شناسایی‌شده', 'ریشه‌های اصلی'],
      for (final cat in state.fishbone.where((n) => n.isCategory))
        [
          cat.title,
          state.fishbone
              .where((n) => n.parentId == cat.id)
              .map((n) => n.title)
              .join('، '),
          state.fishbone
              .where((n) => n.parentId == cat.id && n.isRootCause)
              .map((n) => n.title)
              .join('، '),
        ],
    ]);
    doc.pageBreak();

    // ═══ صفحه ۴: پارتو ═══
    doc.heading('۳) اولویت‌بندی علل — نمودار پارتو (قانون ۸۰/۲۰)');
    if (state.pareto.isNotEmpty) {
      final paretoPng = await ChartImageRenderer.renderPainterPng(
        ParetoReportPainter(
          causes: state.pareto.map((e) => e.cause).toList(),
          freqs: state.pareto.map((e) => e.frequency).toList(),
          cum: state.pareto.map((e) => e.cumulativePercent).toList(),
        ),
        1000,
        420,
      );
      doc.image(paretoPng, widthCm: 15.5, heightCm: 6.5);
      doc.empty();
      doc.table([
        ['رتبه', 'علت', 'فراوانی', 'درصد تجمعی'],
        for (var i = 0; i < state.pareto.length; i++)
          [
            PersianUtils.faDigits('${i + 1}'),
            state.pareto[i].cause,
            state.pareto[i].frequency.toStringAsFixed(0),
            '٪${state.pareto[i].cumulativePercent.toStringAsFixed(0)}',
          ],
      ]);
    } else {
      doc.para('داده‌ای برای پارتو ثبت نشده است.');
    }
    doc.empty();
    doc.heading('درخت ۵ چرا (ریشه‌یابی عمیق)');
    if (state.whysTree.isEmpty) {
      doc.para('درخت ۵ چرا ثبت نشده است.');
    } else {
      for (final n in state.whysTree) {
        final depth = _depth(n.nodeId);
        String? fish;
        if (n.fishboneNodeId != null) {
          final match = state.fishbone.where((f) => f.id == n.fishboneNodeId);
          fish = match.isEmpty ? null : match.first.title;
        }
        doc.para('${'│   ' * depth}└─ ${n.text}'
            '${fish != null ? '  (اتصال به استخوان‌ماهی: $fish)' : ''}',
            size: 20);
      }
    }
    doc.pageBreak();

    // ═══ صفحه ۵: جدول اقدامات 5W2H + گانت ═══
    doc.heading('۴) برنامه‌ی اقدامات (5W2H)');
    doc.table([
      ['چه کاری؟', 'چه کسی؟', 'کجا؟', 'چرا؟', 'چگونه؟', 'چقدر؟', 'پیشرفت'],
      for (final a in state.actions)
        [
          a.metadata['what']?.toString() ?? a.title,
          a.metadata['who']?.toString() ?? '—',
          a.metadata['where']?.toString() ?? '—',
          a.metadata['why']?.toString() ?? '—',
          a.metadata['how']?.toString() ?? '—',
          a.metadata['how_much']?.toString() ?? '—',
          '٪${a.progress}',
        ],
    ]);
    doc.empty();
    doc.heading('گانت چارت زمان‌بندی');
    if (state.gantt.isNotEmpty) {
      final minDate = state.gantt
          .map((t) => t.startDate)
          .reduce((a, b) => a.isBefore(b) ? a : b);
      final maxDate = state.gantt
          .map((t) => t.endDate)
          .reduce((a, b) => a.isAfter(b) ? a : b);
      final days = maxDate.difference(minDate).inDays + 2;
      final ganttPng = await ChartImageRenderer.renderPainterPng(
        GanttPainter(
          tasks: state.gantt,
          minDate: minDate,
          dayWidth: 26,
          rowH: 40,
          headerH: 30,
        ),
        math.max(700.0, days * 26.0 + 40),
        30 + state.gantt.length * 40.0 + 10,
      );
      doc.image(ganttPng, widthCm: 16.2, heightCm: 16.2 * (30 + state.gantt.length * 40.0 + 10) / (days * 26.0 + 40));
    } else {
      doc.para('گانت چارتی ثبت نشده است.');
    }
    doc.pageBreak();

    // ═══ صفحه ۶: بررسی + استانداردسازی + نتیجه‌گیری ═══
    doc.heading('۵) بررسی اثر اقدامات (قبل / بعد)');
    doc.table([
      ['شاخص', 'واحد', 'قبل', 'هدف', 'بعد', 'درصد بهبود'],
      for (final k in state.kpis)
        [
          k.name,
          k.unit,
          k.baseline?.toStringAsFixed(1) ?? '—',
          k.target?.toStringAsFixed(1) ?? '—',
          k.after?.toStringAsFixed(1) ?? '—',
          k.improvementPercent == null
              ? '—'
              : '٪${k.improvementPercent!.toStringAsFixed(1)}',
        ],
    ]);
    doc.empty();
    doc.heading('۶) استانداردسازی (SOP)');
    doc.para(state.sopText.isEmpty ? 'دستورالعملی ثبت نشده است.' : state.sopText);
    if (state.sopReviewDate != null) {
      doc.labelValue('تاریخ بازبینی بعدی استاندارد',
          PersianUtils.faDate(state.sopReviewDate!));
    }
    doc.empty();
    doc.heading('۷) نتیجه‌گیری');
    doc.para(
      'با اجرای چرخه‌ی PDCA، ریشه‌های اصلی مسئله حذف و اثر اقدامات از طریق شاخص‌های فوق تأیید شد. '
      'دستورالعمل جدید جهت جلوگیری از تکرار مشکل استانداردسازی گردید.',
    );
    doc.empty();
    doc.para('— پایان گزارش — تولیدشده توسط ${AppConstants.appName} • ${AppConstants.creator}',
        center: true, size: 18, color: '888888');

    // ═══ ذخیره در Downloads ═══
    final dir = await resolveDownloadsDir();
    final path = p.join(dir.path, 'GerehGosha-L2-Report-${state.problemId ?? 0}.docx');
    await File(path).writeAsBytes(doc.build(), flush: true);
    return path;
  }

  int _depth(String nodeId, [int d = 0]) {
    final match = state.whysTree.where((n) => n.nodeId == nodeId);
    if (match.isEmpty || match.first.parentId == null) return d;
    return _depth(match.first.parentId!, d + 1);
  }

  // دسترسی به state برای _depth
  late final Level2State state;
}
