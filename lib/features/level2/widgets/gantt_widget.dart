import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/persian_utils.dart';
import '../../../data/models/gantt_task.dart';
import '../level2_provider.dart';

/// رنگ نوار بر اساس وضعیت اقدام
Color ganttStatusColor(String status) => switch (status) {
      GanttStatus.inProgress => AppColors.orange,
      GanttStatus.done => AppColors.success,
      GanttStatus.canceled => AppColors.level3,
      _ => const Color(0xFF94A3B8),
    };

/// گانت چارت سفارشی: نوارهای افقی رنگی، شبکه‌ی روزها، فلش وابستگی،
/// زوم (اسلایدر) و اسکرول افقی.
class GanttWidget extends ConsumerStatefulWidget {
  const GanttWidget({super.key, this.heightLimit = 320});

  final double heightLimit;

  @override
  ConsumerState<GanttWidget> createState() => _GanttWidgetState();
}

class _GanttWidgetState extends ConsumerState<GanttWidget> {
  double _dayWidth = 22; // زوم

  static const double _rowH = 40;
  static const double _headerH = 30;
  static const double _labelW = 150;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(level2WizardProvider);
    final tasks = state.gantt;
    final theme = Theme.of(context);

    if (tasks.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.dividerColor.withValues(alpha: .6)),
        ),
        child: const Text('هنوز اقدامی برای زمان‌بندی ثبت نشده است؛'
            ' در جدول 5W2H بالای همین گام، اقدام بسازید تا نوار گانت آن ساخته شود.'),
      );
    }

    final minDate = tasks.map((t) => t.startDate).reduce((a, b) => a.isBefore(b) ? a : b);
    final maxDate = tasks.map((t) => t.endDate).reduce((a, b) => a.isAfter(b) ? a : b);
    final days = maxDate.difference(minDate).inDays + 2;
    final chartW = days * _dayWidth + 40;
    final chartH = _headerH + tasks.length * _rowH + 10;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // کنترل زوم + راهنمای رنگ‌ها
        Row(
          children: [
            const Icon(Icons.zoom_in, size: 18),
            SizedBox(
              width: 150,
              child: Slider(
                min: 10,
                max: 52,
                value: _dayWidth,
                onChanged: (v) => setState(() => _dayWidth = v),
              ),
            ),
            const Spacer(),
            for (final s in const [
              GanttStatus.notStarted,
              GanttStatus.inProgress,
              GanttStatus.done,
            ]) ...[
              Container(width: 12, height: 12,
                  decoration: BoxDecoration(
                      color: ganttStatusColor(s), borderRadius: BorderRadius.circular(3))),
              const SizedBox(width: 4),
              Text(GanttStatus.faLabels[s]!, style: const TextStyle(fontSize: 11)),
              const SizedBox(width: 10),
            ],
          ],
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: chartH.clamp(120, widget.heightLimit),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ستون عنوان‌ها (ثابت، سمت راست در RTL)
              Container(
                width: _labelW,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  border: Border(
                      left: BorderSide(
                          color: theme.dividerColor.withValues(alpha: .6))),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: _headerH),
                    for (final t in tasks)
                      SizedBox(
                        height: _rowH,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              t.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // ناحیه‌ی قابل اسکرول افقی
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: GestureDetector(
                    onTapUp: (d) {
                      final y = d.localPosition.dy - _headerH;
                      final idx = (y / _rowH).floor();
                      if (idx >= 0 && idx < tasks.length) {
                        _showTaskDialog(tasks[idx]);
                      }
                    },
                    child: CustomPaint(
                      size: Size(chartW, chartH),
                      painter: GanttPainter(
                        tasks: tasks,
                        minDate: minDate,
                        dayWidth: _dayWidth,
                        rowH: _rowH,
                        headerH: _headerH,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showTaskDialog(GanttTask t) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('شروع: ${PersianUtils.faDate(t.startDate)}'),
            Text('پایان: ${PersianUtils.faDate(t.endDate)}'),
            Text('وضعیت: ${GanttStatus.faLabels[t.status]}'),
            Text('پیشرفت: ٪${PersianUtils.faDigits('${t.progress}')}'),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('بستن')),
        ],
      ),
    );
  }
}

class GanttPainter extends CustomPainter {
  GanttPainter({
    required this.tasks,
    required this.minDate,
    required this.dayWidth,
    required this.rowH,
    required this.headerH,
  });

  final List<GanttTask> tasks;
  final DateTime minDate;
  final double dayWidth;
  final double rowH;
  final double headerH;

  double _x(DateTime d) =>
      20 + d.difference(minDate).inDays * dayWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final days = ((size.width - 40) / dayWidth).ceil();

    // شبکه‌ی عمودی روزها + برچسب تاریخ
    final grid = Paint()
      ..color = const Color(0x2294A3B8)
      ..strokeWidth = 1;
    for (var d = 0; d <= days; d++) {
      final x = 20 + d * dayWidth;
      canvas.drawLine(Offset(x, headerH), Offset(x, size.height), grid);
      if (d % 2 == 0 && dayWidth >= 18) {
        final date = minDate.add(Duration(days: d));
        final tp = TextPainter(
          text: TextSpan(
            text: PersianUtils.faDigits('${date.month}/${date.day}'),
            style: const TextStyle(
                fontFamily: 'Vazirmatn', fontSize: 9, color: Color(0xFF64748B)),
          ),
          textDirection: TextDirection.rtl,
        )..layout();
        tp.paint(canvas, Offset(x - tp.width / 2, 6));
      }
    }

    // خطوط افقی ردیف‌ها
    for (var i = 0; i <= tasks.length; i++) {
      final y = headerH + i * rowH;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    // نوارها
    final posOf = <int?, Rect>{};
    for (var i = 0; i < tasks.length; i++) {
      final t = tasks[i];
      final x1 = _x(t.startDate);
      final x2 = _x(t.endDate) + dayWidth;
      final y = headerH + i * rowH + 8;
      final h = rowH - 16;
      final rect = Rect.fromLTWH(x1, y, (x2 - x1).clamp(10, 4000), h);
      posOf[t.id] = rect;

      final color = ganttStatusColor(t.status);
      canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(7)),
          Paint()..color = color.withValues(alpha: .35));
      // بخش پیشرفت
      if (t.progress > 0) {
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromLTWH(rect.left, rect.top, rect.width * t.progress / 100, h),
                const Radius.circular(7)),
            Paint()..color = color);
      }
      canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(7)),
          Paint()
            ..color = color
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5);

      // درصد روی نوار
      final tp = TextPainter(
        text: TextSpan(
          text: '٪${PersianUtils.faDigits('${t.progress}')}',
          style: const TextStyle(
              fontFamily: 'Vazirmatn',
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Colors.black87),
        ),
        textDirection: TextDirection.rtl,
      )..layout();
      tp.paint(canvas, Offset(rect.center.dx - tp.width / 2, rect.center.dy - tp.height / 2));
    }

    // فلش وابستگی
    final arrow = Paint()
      ..color = const Color(0xFF64748B)
      ..strokeWidth = 1.5;
    for (final t in tasks) {
      if (t.dependsOn == null) continue;
      final from = posOf[t.dependsOn];
      final to = posOf[t.id];
      if (from == null || to == null) continue;
      final p1 = Offset(from.left - 2, from.center.dy);
      final p2 = Offset(to.right + 2, to.center.dy);
      final path = Path()
        ..moveTo(p1.dx, p1.dy)
        ..lineTo(p1.dx - 8, p1.dy)
        ..lineTo(p1.dx - 8, p2.dy)
        ..lineTo(p2.dx, p2.dy);
      canvas.drawPath(path, arrow);
      canvas.drawCircle(p2, 3, Paint()..color = const Color(0xFF64748B));
    }
  }

  @override
  bool shouldRepaint(covariant GanttPainter old) =>
      old.tasks != tasks || old.dayWidth != dayWidth;
}
