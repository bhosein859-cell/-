import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/persian_utils.dart';
import '../../../data/models/level3_models.dart';
import '../level3_provider.dart';

/// جدول تعاملی FMEA با محاسبه‌ی خودکار RPN = S × O × D،
/// اولویت‌بندی نزولی، پارتوی RPN و پیشنهاد اقدام برای حالات بحرانی.
class FmeaWidget extends ConsumerWidget {
  const FmeaWidget({super.key});

  Future<void> _editDialog(BuildContext context, WidgetRef ref,
      [FmeaItem? existing]) async {
    final notifier = ref.read(level3WizardProvider.notifier);
    final problemId = ref.read(level3WizardProvider).problemId!;

    final item = TextEditingController(text: existing?.itemName ?? '');
    final mode = TextEditingController(text: existing?.failureMode ?? '');
    final effect = TextEditingController(text: existing?.effect ?? '');
    final cause = TextEditingController(text: existing?.cause ?? '');
    final control = TextEditingController(text: existing?.control ?? '');
    int s = existing?.severity ?? 5;
    int o = existing?.occurrence ?? 5;
    int d = existing?.detection ?? 5;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('سطر FMEA'),
          content: SizedBox(
            width: 460,
            child: ListView(
              shrinkWrap: true,
              children: [
                TextField(controller: item, decoration: const InputDecoration(labelText: 'آیتم / فرایند')),
                TextField(controller: mode, decoration: const InputDecoration(labelText: 'حالت خرابی')),
                TextField(controller: effect, decoration: const InputDecoration(labelText: 'اثر خرابی')),
                TextField(controller: cause, decoration: const InputDecoration(labelText: 'علت خرابی')),
                TextField(controller: control, decoration: const InputDecoration(labelText: 'کنترل فعلی')),
                _slider('شدت (S)', s, (v) => setS(() => s = v)),
                _slider('وقوع (O)', o, (v) => setS(() => o = v)),
                _slider('شناسایی (D)', d, (v) => setS(() => d = v)),
                Center(
                  child: Text(
                    'RPN = ${PersianUtils.faDigits('${s * o * d}')}'
                    '${s * o * d >= 100 ? ' ⚠ بحرانی' : ''}',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      color: s * o * d >= 100 ? AppColors.level3 : AppColors.navyBlue,
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('انصراف')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('ذخیره')),
          ],
        ),
      ),
    );
    if (ok != true || item.text.trim().isEmpty) return;

    if (existing == null) {
      await notifier.addFmea(FmeaItem(
        problemId: problemId,
        itemName: item.text.trim(),
        failureMode: mode.text.trim(),
        effect: effect.text.trim(),
        severity: s,
        cause: cause.text.trim(),
        occurrence: o,
        control: control.text,
        detection: d,
      ));
    } else {
      await notifier.updateFmea(existing.id!, {
        'item_name': item.text.trim(),
        'failure_mode': mode.text.trim(),
        'effect': effect.text.trim(),
        's': s,
        'cause': cause.text.trim(),
        'o': o,
        'control': control.text,
        'd': d,
        'rpn': s * o * d,
      });
    }
  }

  Widget _slider(String label, int value, ValueChanged<int> onChanged) => Row(
        children: [
          SizedBox(width: 80, child: Text(label, style: const TextStyle(fontSize: 13))),
          Expanded(
            child: Slider(
              min: 1,
              max: 10,
              divisions: 9,
              value: value.toDouble(),
              label: PersianUtils.faDigits('$value'),
              onChanged: (v) => onChanged(v.round()),
            ),
          ),
          SizedBox(width: 30, child: Text(PersianUtils.faDigits('$value'),
              style: const TextStyle(fontWeight: FontWeight.w800))),
        ],
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(level3WizardProvider);
    final notifier = ref.read(level3WizardProvider.notifier);
    final theme = Theme.of(context);
    final rows = state.fmea; // repository بر اساس RPN نزولی مرتب می‌کند

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            FilledButton.icon(
              onPressed: () => _editDialog(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('افزودن حالت خرابی'),
            ),
            const Spacer(),
            Text(
              'بحرانی‌ها (RPN≥۱۰۰): ${PersianUtils.faDigits('${rows.where((r) => r.isCritical).length}')}',
              style: const TextStyle(
                  fontWeight: FontWeight.w800, color: AppColors.level3),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // جدول FMEA
        if (rows.isNotEmpty)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStatePropertyAll(
                  AppColors.navyBlue.withValues(alpha: .08)),
              columns: const [
                DataColumn(label: Text('آیتم')),
                DataColumn(label: Text('حالت خرابی')),
                DataColumn(label: Text('اثر')),
                DataColumn(label: Text('S')),
                DataColumn(label: Text('علت')),
                DataColumn(label: Text('O')),
                DataColumn(label: Text('کنترل')),
                DataColumn(label: Text('D')),
                DataColumn(label: Text('RPN')),
                DataColumn(label: Text('')),
              ],
              rows: [
                for (final f in rows)
                  DataRow(
                    color: WidgetStatePropertyAll(
                        f.isCritical ? AppColors.level3.withValues(alpha: .08) : null),
                    cells: [
                      DataCell(Text(f.itemName)),
                      DataCell(Text(f.failureMode)),
                      DataCell(Text(f.effect)),
                      DataCell(Text(PersianUtils.faDigits('${f.severity}'))),
                      DataCell(Text(f.cause)),
                      DataCell(Text(PersianUtils.faDigits('${f.occurrence}'))),
                      DataCell(Text(f.control)),
                      DataCell(Text(PersianUtils.faDigits('${f.detection}'))),
                      DataCell(Text(
                        PersianUtils.faDigits('${f.rpn}'),
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: f.isCritical ? AppColors.level3 : AppColors.navyBlue,
                        ),
                      )),
                      DataCell(Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (f.isCritical)
                            IconButton(
                              tooltip: 'پیشنهاد اقدام اصلاحی',
                              icon: const Icon(Icons.lightbulb_outline,
                                  color: AppColors.orange),
                              onPressed: () => notifier.updateFmea(f.id!, {
                                'proposed_action': notifier.proposeAction(f),
                              }),
                            ),
                          IconButton(
                            icon: const Icon(Icons.edit, size: 18),
                            onPressed: () => _editDialog(context, ref, f),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 18,
                                color: AppColors.level3),
                            onPressed: () => notifier.deleteFmea(f.id!),
                          ),
                        ],
                      )),
                    ],
                  ),
              ],
            ),
          ),

        // اقدامات پیشنهادی شده
        for (final f in rows.where((r) => r.proposedAction != null))
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.orange.withValues(alpha: .08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.orange.withValues(alpha: .4)),
            ),
            child: Text(
              '💡 اقدام پیشنهادی برای «${f.failureMode}» (RPN=${PersianUtils.faDigits('${f.rpn}')}): ${f.proposedAction}',
              style: const TextStyle(fontSize: 12.5),
            ),
          ),
        const SizedBox(height: 16),

        // پارتوی RPN
        if (rows.isNotEmpty) ...[
          Text('پارتوی RPN — بحرانی‌ترین حالت‌ها',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                barGroups: [
                  for (var i = 0; i < rows.length && i < 10; i++)
                    BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: rows[i].rpn.toDouble(),
                          color: rows[i].isCritical
                              ? AppColors.level3
                              : AppColors.navyBlue.withValues(alpha: .5),
                          width: 22,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
                        ),
                      ],
                    ),
                ],
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (g, gi, rod, ri) => BarTooltipItem(
                      '${rows[g.x].failureMode}\nRPN: ${PersianUtils.faDigits('${rows[g.x].rpn}')}',
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
                        v.toInt() < rows.length
                            ? (rows[v.toInt()].failureMode.length > 8
                                ? '${rows[v.toInt()].failureMode.substring(0, 8)}…'
                                : rows[v.toInt()].failureMode)
                            : '',
                        style: const TextStyle(fontSize: 9),
                      ),
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (v, m) => Text(
                          PersianUtils.faDigits(v.toStringAsFixed(0)),
                          style: const TextStyle(fontSize: 10)),
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: false),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
