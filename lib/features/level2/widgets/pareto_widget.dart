import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/persian_utils.dart';
import '../../../data/models/pareto_entry.dart';
import '../level2_provider.dart';

/// نمودار پارتو تعاملی: میله‌های فراوانی + خط درصد تجمعی.
/// ورودی کاربر → مرتب‌سازی خودکار نزولی + محاسبه‌ی تجمعی + هایلایت «چند حیاتی» (۸۰/۲۰).
class ParetoWidget extends ConsumerStatefulWidget {
  const ParetoWidget({super.key});

  @override
  ConsumerState<ParetoWidget> createState() => _ParetoWidgetState();
}

class _ParetoWidgetState extends ConsumerState<ParetoWidget> {
  final List<_Draft> _drafts = [];

  Future<void> _commit() async {
    final state = ref.read(level2WizardProvider);
    final entries = [
      ...state.pareto.map((e) => ParetoEntry(
          problemId: e.problemId, cause: e.cause, frequency: e.frequency)),
      for (final d in _drafts)
        if (d.cause.trim().isNotEmpty && d.freq > 0)
          ParetoEntry(problemId: state.problemId!, cause: d.cause, frequency: d.freq),
    ];
    _drafts.clear();
    await ref.read(level2WizardProvider.notifier).savePareto(entries);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(level2WizardProvider);
    final data = state.pareto;
    final theme = Theme.of(context);
    final maxFreq = data.isEmpty ? 10.0 : data.map((e) => e.frequency).reduce((a, b) => a > b ? a : b);
    final maxY = maxFreq * 1.2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (data.isNotEmpty)
          SizedBox(
            height: 260,
            child: Stack(
              children: [
                // ── میله‌های فراوانی ──
                BarChart(
                  BarChartData(
                    maxY: maxY,
                    alignment: BarChartAlignment.spaceAround,
                    barGroups: [
                      for (var i = 0; i < data.length; i++)
                        BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: data[i].frequency,
                              color: data[i].cumulativePercent <= 80
                                  ? AppColors.orange
                                  : AppColors.navyBlue.withValues(alpha: .45),
                              width: 26,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                            ),
                          ],
                        ),
                    ],
                    borderData: FlBorderData(show: false),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (v) => BorderSide(
                          color: theme.dividerColor.withValues(alpha: .4)),
                    ),
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 34,
                          getTitlesWidget: (v, meta) => Text(
                            PersianUtils.faDigits('${v.toInt()}'),
                            style: const TextStyle(fontSize: 10),
                          ),
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (v, meta) => Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              v.toInt() < data.length
                                  ? _short(data[v.toInt()].cause, 10)
                                  : '',
                              style: const TextStyle(fontSize: 10),
                            ),
                          ),
                        ),
                      ),
                    ),
                    barTouchData: BarTouchData(
                      touchTooltipData: BarTouchTooltipData(
                        tooltipRoundedRadius: 10,
                        getTooltipItem: (group, gIndex, rod, rIndex) {
                          final e = data[group.x];
                          return BarTooltipItem(
                            '${e.cause}\nفراوانی: ${PersianUtils.faDigits(e.frequency.toStringAsFixed(0))}'
                            '\nتجمعی: ٪${PersianUtils.faDigits(e.cumulativePercent.toStringAsFixed(0))}',
                            const TextStyle(
                                fontFamily: 'Vazirmatn', fontSize: 12, color: Colors.white),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                // ── خط درصد تجمعی (مقیاس‌شده روی همان محور) ──
                IgnorePointer(
                  child: LineChart(
                    LineChartData(
                      maxY: maxY,
                      lineBarsData: [
                        LineChartBarData(
                          spots: [
                            for (var i = 0; i < data.length; i++)
                              FlSpot(i.toDouble(), data[i].cumulativePercent / 100 * maxY),
                          ],
                          isCurved: false,
                          color: AppColors.level3,
                          barWidth: 2.5,
                          dotData: FlDotData(
                            getDotPainter: (spot, percent, bar, index) =>
                                FlDotCirclePainter(
                                    radius: 4,
                                    color: AppColors.level3,
                                    strokeWidth: 1.5,
                                    strokeColor: Colors.white),
                          ),
                        ),
                      ],
                      // خط‌چین آستانه‌ی ۸۰٪ (قانون پارتو)
                      extraLinesData: ExtraLinesData(horizontalLines: [
                        HorizontalLine(
                          y: 0.8 * maxY,
                          color: AppColors.level3.withValues(alpha: .6),
                          strokeWidth: 1.5,
                          dashArray: [6, 6],
                        ),
                      ]),
                      titlesData: const FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      gridData: const FlGridData(show: false),
                      lineTouchData: const LineTouchData(enabled: false),
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (data.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '🔶 میله‌های نارنجی = «چند علت حیاتی» (تا ۸۰٪ اثر) • خط قرمز = درصد تجمعی و آستانه‌ی ۸۰٪',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
        const SizedBox(height: 14),

        // ── ورودی داده‌های فراوانی ──
        for (var i = 0; i < _drafts.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _drafts[i].causeController,
                    decoration: const InputDecoration(hintText: 'علت…'),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 90,
                  child: TextField(
                    controller: _drafts[i].freqController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(hintText: 'فراوانی'),
                    onChanged: (v) => _drafts[i].freq = double.tryParse(v) ?? 0,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () => setState(() => _drafts.removeAt(i)),
                ),
              ],
            ),
          ),
        Wrap(
          spacing: 10,
          children: [
            OutlinedButton.icon(
              onPressed: () => setState(() => _drafts.add(_Draft())),
              icon: const Icon(Icons.add),
              label: const Text('افزودن علت'),
            ),
            FilledButton.icon(
              onPressed: _drafts.isEmpty ? null : _commit,
              icon: const Icon(Icons.refresh),
              label: const Text('رسم نمودار'),
            ),
          ],
        ),
      ],
    );
  }
}

String _short(String s, int n) => s.length <= n ? s : '${s.substring(0, n)}…';

class _Draft {
  _Draft() {
    causeController = TextEditingController();
    freqController = TextEditingController();
  }
  late final TextEditingController causeController;
  late final TextEditingController freqController;
  double freq = 0;
  String get cause => causeController.text;
}
