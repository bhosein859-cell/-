import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/persian_utils.dart';
import '../level2_provider.dart';

/// گام ۶: بررسی — مقایسه‌ی قبل/بعد شاخص‌ها با نمودار میله‌ای دوستونه
/// + محاسبه‌ی خودکار درصد بهبود.
class Step6Check extends ConsumerWidget {
  const Step6Check({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(level2WizardProvider);
    final notifier = ref.read(level2WizardProvider.notifier);
    final theme = Theme.of(context);
    final kpis = state.kpis;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('بررسی — مقایسه‌ی قبل و بعد از اقدام',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Text('مقدار «بعد» هر شاخص را ثبت کنید تا تفاوت به‌صورت گرافیکی نمایش داده شود.',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 16),

        if (kpis.isEmpty) const Text('در گام ۱ شاخصی ثبت نشده است.'),

        // ورودی مقادیر «بعد» + درصد بهبود
        for (var i = 0; i < kpis.length; i++) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.dividerColor.withValues(alpha: .6)),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    '${kpis[i].name}\nقبل: ${kpis[i].baseline ?? '—'} ${kpis[i].unit}',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                Expanded(
                  child: TextField(
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'بعد از اقدام'),
                    onChanged: (v) =>
                        notifier.setKpiAfter(i, double.tryParse(v)),
                  ),
                ),
                const SizedBox(width: 10),
                Builder(builder: (context) {
                  final imp = kpis[i].improvementPercent;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: (imp ?? 0) >= 0
                          ? AppColors.success.withValues(alpha: .12)
                          : AppColors.level3.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      imp == null
                          ? '—'
                          : '٪${PersianUtils.faDigits(imp.toStringAsFixed(1))} ${imp >= 0 ? 'بهبود ▲' : 'کاهش ▼'}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: (imp ?? 0) >= 0 ? AppColors.success : AppColors.level3,
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
        const SizedBox(height: 10),

        // نمودار میله‌ای دوستونه (قبل / بعد)
        if (kpis.isNotEmpty)
          SizedBox(
            height: 260,
            child: BarChart(
              BarChartData(
                barGroups: [
                  for (var i = 0; i < kpis.length; i++)
                    BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: kpis[i].baseline ?? 0,
                          color: AppColors.navyBlue,
                          width: 20,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
                        ),
                        BarChartRodData(
                          toY: kpis[i].after ?? 0,
                          color: AppColors.orange,
                          width: 20,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
                        ),
                      ],
                    ),
                ],
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, gIndex, rod, rIndex) {
                      final k = kpis[group.x];
                      final isBefore = rIndex == 0;
                      return BarTooltipItem(
                        '${k.name}\n${isBefore ? 'قبل' : 'بعد'}: '
                        '${PersianUtils.faDigits(((isBefore ? k.baseline : k.after) ?? 0).toStringAsFixed(1))} ${k.unit}',
                        const TextStyle(fontFamily: 'Vazirmatn', fontSize: 12, color: Colors.white),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 34,
                      getTitlesWidget: (v, m) => Text(PersianUtils.faDigits(v.toStringAsFixed(0)),
                          style: const TextStyle(fontSize: 10)),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, m) => Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          v.toInt() < kpis.length
                              ? _short(kpis[v.toInt()].name, 12)
                              : '',
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (v) =>
                        FlLine(
                          color: theme.dividerColor.withValues(alpha: .4),
                          strokeWidth: .5)),
              ),
            ),
          ),
        const Padding(
          padding: EdgeInsets.only(top: 8),
          child: Row(
            children: [
              _LegendDot(color: AppColors.navyBlue, label: 'قبل از اقدام'),
              SizedBox(width: 16),
              _LegendDot(color: AppColors.orange, label: 'بعد از اقدام'),
            ],
          ),
        ),
      ],
    );
  }
}

String _short(String s, int n) => s.length <= n ? s : '${s.substring(0, n)}…';

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(width: 12, height: 12,
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      );
}
