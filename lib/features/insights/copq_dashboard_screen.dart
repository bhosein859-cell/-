import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/persian_utils.dart';
import '../../data/database/database_helper.dart';

/// ═══════════════════════════════════════════════════════════════
/// محاسبه‌گر زنده‌ی هزینه کیفیت پایین (COPQ Live)
/// جمع‌آوری لحظه‌ای هزینه‌ها از تمام پروژه‌ها + نمودار دایره‌ای
/// سهم دسته‌ها و میله‌ای مقایسه قبل/بعد.
/// ═══════════════════════════════════════════════════════════════
class CopqDashboardScreen extends ConsumerStatefulWidget {
  const CopqDashboardScreen({super.key});

  @override
  ConsumerState<CopqDashboardScreen> createState() =>
      _CopqDashboardScreenState();
}

class _CopqDashboardScreenState extends ConsumerState<CopqDashboardScreen> {
  static const Map<String, String> _fa = {
    'internal': 'شکست داخلی',
    'external': 'شکست خارجی',
    'appraisal': 'ارزیابی',
    'prevention': 'پیشگیری',
  };
  static const List<Color> _palette = [
    AppColors.level3, AppColors.level2, AppColors.navyBlue, AppColors.success,
  ];

  Map<String, (double, double)> _rows = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final db = await ref.read(databaseProvider).database;
    final rows = await db.query('copq');
    final acc = <String, (double, double)>{};
    for (final r in rows) {
      final cat = r['category'] as String? ?? 'internal';
      final cur = acc[cat] ?? (0.0, 0.0);
      acc[cat] = (
        cur.$1 + (r['before'] as num?)!.toDouble(),
        cur.$2 + (r['after'] as num?)!.toDouble(),
      );
    }
    setState(() {
      _rows = acc;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalBefore = _rows.values.fold(0.0, (s, r) => s + r.$1);
    final totalAfter = _rows.values.fold(0.0, (s, r) => s + r.$2);
    final saving = totalBefore - totalAfter;

    return Scaffold(
      appBar: AppBar(title: const Text('داشبورد زنده‌ی هزینه کیفیت پایین')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _rows.isEmpty
              ? const Center(
                  child: Text('هنوز داده‌ی COPQ در پروژه‌های سطح ۳ ثبت نشده است.'))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // ── شاخص‌های کلیدی ──
                      Row(
                        children: [
                          Expanded(child: _kpi('جمع هزینه قبل',
                              totalBefore, AppColors.level3)),
                          const SizedBox(width: 10),
                          Expanded(child: _kpi('جمع هزینه بعد',
                              totalAfter, AppColors.navyBlue)),
                          const SizedBox(width: 10),
                          Expanded(child: _kpi('صرفه‌جویی',
                              saving, AppColors.success)),
                        ],
                      ),
                      const SizedBox(height: 18),

                      Text('سهم دسته‌های هزینه (قبل)',
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 220,
                        child: PieChart(
                          PieChartData(
                            sections: [
                              for (var i = 0; i < _rows.entries.length; i++)
                                PieChartSectionData(
                                  value: _rows.entries.elementAt(i).value.$1,
                                  color: _palette[i % _palette.length],
                                  title:
                                      '${(_rows.entries.elementAt(i).value.$1 / (totalBefore == 0 ? 1 : totalBefore) * 100).toStringAsFixed(0)}٪',
                                  titleStyle: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800),
                                  radius: 70,
                                ),
                            ],
                            centerSpaceRadius: 36,
                          ),
                        ),
                      ),
                      Wrap(
                        spacing: 14,
                        children: [
                          for (var i = 0; i < _rows.entries.length; i++)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                      color: _palette[i % _palette.length],
                                      shape: BoxShape.circle),
                                ),
                                const SizedBox(width: 4),
                                Text(_fa[_rows.entries.elementAt(i).key] ??
                                    _rows.entries.elementAt(i).key,
                                    style: const TextStyle(fontSize: 12)),
                              ],
                            ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      Text('مقایسه قبل/بعد به تفکیک دسته',
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 240,
                        child: BarChart(
                          BarChartData(
                            groupsSpace: 30,
                            barGroups: [
                              for (var i = 0; i < _rows.entries.length; i++)
                                BarChartGroupData(x: i, barsSpace: 4, barRods: [
                                  BarChartRodData(
                                    toY: _rows.entries.elementAt(i).value.$1,
                                    color: AppColors.level3,
                                    width: 18,
                                  ),
                                  BarChartRodData(
                                    toY: _rows.entries.elementAt(i).value.$2,
                                    color: AppColors.success,
                                    width: 18,
                                  ),
                                ]),
                            ],
                            titlesData: FlTitlesData(
                              topTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false)),
                              rightTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false)),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 48,
                                  getTitlesWidget: (v, m) => Text(
                                    PersianUtils.faDigits(
                                        '${(v / 1000000).toStringAsFixed(1)}M'),
                                    style: const TextStyle(fontSize: 9),
                                  ),
                                ),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (v, m) => Text(
                                    (_fa[_rows.entries
                                                .elementAt(v.toInt())
                                                .key] ??
                                            '')
                                        .split(' ')
                                        .first,
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                ),
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            gridData: const FlGridData(show: false),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _legend(AppColors.level3, 'قبل'),
                          const SizedBox(width: 12),
                          _legend(AppColors.success, 'بعد'),
                        ],
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _kpi(String label, double value, Color color) => Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Text(PersianUtils.faDigits(value.toStringAsFixed(0)),
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w900, color: color)),
              Text(label,
                  style:
                      const TextStyle(fontSize: 11, color: Colors.black54)),
            ],
          ),
        ),
      );

  Widget _legend(Color c, String label) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 12, height: 12, color: c),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      );
}
