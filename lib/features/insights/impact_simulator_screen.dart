import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/persian_utils.dart';

/// ═══════════════════════════════════════════════════════════════
/// شبیه‌ساز تأثیر (Impact Simulator)
/// اگر این مشکل حل نشود، چه هزینه‌ای به سازمان تحمیل می‌شود؟
/// مقایسه‌ی بصری «هزینه حل مسئله» در برابر «هزینه حل نکردن».
/// ═══════════════════════════════════════════════════════════════
class ImpactSimulatorScreen extends StatefulWidget {
  const ImpactSimulatorScreen({super.key});

  @override
  State<ImpactSimulatorScreen> createState() => _ImpactSimulatorScreenState();
}

class _ImpactSimulatorScreenState extends State<ImpactSimulatorScreen> {
  final _daily = TextEditingController(text: '1000000');
  final _days = TextEditingController(text: '30');
  final _defective = TextEditingController(text: '50');
  final _unitPrice = TextEditingController(text: '20000');
  final _fixCost = TextEditingController(text: '5000000');

  double _num(TextEditingController c) =>
      double.tryParse(c.text.replaceAll(',', '')) ?? 0;

  double get ignoreCost =>
      _num(_daily) * _num(_days) + _num(_defective) * _num(_unitPrice);
  double get fixCost => _num(_fixCost);
  double get savings => ignoreCost - fixCost;

  @override
  void dispose() {
    for (final c in [_daily, _days, _defective, _unitPrice, _fixCost]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('شبیه‌ساز تأثیر تصمیم')),
      body: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'اگر این مشکل حل نشود چه اتفاقی می‌افتد؟ مقادیر را وارد کنید '
                    'تا هزینه‌ی بی‌توجهی در برابر هزینه‌ی حل مقایسه شود.',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: Colors.black54),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _field(_daily, 'هزینه روزانه تحمیل‌شده'),
                      _field(_days, 'تعداد روز ادامه مشکل'),
                      _field(_defective, 'تعداد محصول معیوب در روز'),
                      _field(_unitPrice, 'قیمت هر محصول معیوب'),
                      _field(_fixCost, 'هزینه اجرای راه‌حل'),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // ── نمودار مقایسه ──
                  SizedBox(
                    height: 260,
                    child: BarChart(
                      BarChartData(
                        maxY: (ignoreCost > fixCost ? ignoreCost : fixCost) * 1.25,
                        barGroups: [
                          BarChartGroupData(x: 0, barRods: [
                            BarChartRodData(
                              toY: ignoreCost,
                              color: AppColors.level3,
                              width: 46,
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(6)),
                            ),
                          ]),
                          BarChartGroupData(x: 1, barRods: [
                            BarChartRodData(
                              toY: fixCost,
                              color: AppColors.success,
                              width: 46,
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(6)),
                            ),
                          ]),
                        ],
                        barTouchData: BarTouchData(
                          touchTooltipData: BarTouchTooltipData(
                            getTooltipItem: (g, gi, rod, ri) => BarTooltipItem(
                              PersianUtils.faDigits(
                                  rod.toY.toStringAsFixed(0)),
                              const TextStyle(
                                  fontFamily: 'Vazirmatn',
                                  color: Colors.white),
                            ),
                          ),
                        ),
                        titlesData: FlTitlesData(
                          topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 64,
                              getTitlesWidget: (v, m) => Text(
                                PersianUtils.faDigits(
                                    '${(v / 1000000).toStringAsFixed(1)}M'),
                                style: const TextStyle(fontSize: 10),
                              ),
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (v, m) => Text(
                                v == 0 ? 'حل نشود ⛔' : 'حل شود ✓',
                                style: const TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.w800),
                              ),
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        gridData: FlGridData(
                          getDrawingHorizontalLine: (v) => BorderSide(
                              color: AppColors.navyBlue.withValues(alpha: .08)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ── جمع‌بندی ──
                  Card(
                    color: savings > 0
                        ? AppColors.success.withValues(alpha: .08)
                        : AppColors.level3.withValues(alpha: .08),
                    child: ListTile(
                      leading: Icon(
                        savings > 0 ? Icons.trending_up : Icons.warning_amber,
                        color: savings > 0
                            ? AppColors.success
                            : AppColors.level3,
                      ),
                      title: Text(
                        savings > 0
                            ? 'با حل مسئله، ${PersianUtils.faDigits(savings.toStringAsFixed(0))} واحد پول صرفه‌جویی می‌شود.'
                            : 'با این مقادیر، هزینه حل بیش از هزینه ادامه است؛ ورودی‌ها را بازبینی کنید.',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: Text(
                        'هزینه بی‌توجهی: ${PersianUtils.faDigits(ignoreCost.toStringAsFixed(0))}'
                        ' | هزینه حل: ${PersianUtils.faDigits(fixCost.toStringAsFixed(0))}',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String label) => SizedBox(
        width: 180,
        child: TextField(
          controller: c,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: label),
          onChanged: (_) => setState(() {}),
        ),
      );
}
