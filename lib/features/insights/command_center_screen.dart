import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/persian_utils.dart';
import '../../data/database/database_helper.dart';
import '../../services/reminder_service.dart';

/// ═══════════════════════════════════════════════════════════════
/// اتاق فرمان (Command Center) — نمای کلان تمام پروژه‌های فعال
/// شاخص‌های کلیدی + یادآورهای هوشمند + تفکیک سطح، در یک نگاه.
/// ═══════════════════════════════════════════════════════════════
class CommandCenterScreen extends ConsumerStatefulWidget {
  const CommandCenterScreen({super.key});

  @override
  ConsumerState<CommandCenterScreen> createState() =>
      _CommandCenterScreenState();
}

class _CommandCenterScreenState extends ConsumerState<CommandCenterScreen> {
  Map<String, int> _counts = {};
  List<DueAction> _due = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final db = await ref.read(databaseProvider).database;
    final rows = await db.rawQuery('''
      SELECT level, status, COUNT(*) AS c FROM problems
      WHERE is_archived = 0 GROUP BY level, status
    ''');
    final counts = <String, int>{
      'open': 0, 'in_progress': 0, 'closed': 0,
      'l1': 0, 'l2': 0, 'l3': 0,
    };
    for (final r in rows) {
      final c = r['c'] as int? ?? 0;
      counts[r['status'] as String? ?? 'open'] =
          (counts[r['status'] as String? ?? 'open'] ?? 0) + c;
      counts['l${r['level']}'] = c;
    }
    final due = await ref.read(reminderProvider).overdueAndToday();
    due.sort((a, b) =>
        ReminderService.urgency(b).compareTo(ReminderService.urgency(a)));
    setState(() {
      _counts = counts;
      _due = due;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('🎛 اتاق فرمان')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text('نمای کلی',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _kpi('باز', _counts['open'] ?? 0, AppColors.navyBlue),
                      const SizedBox(width: 10),
                      _kpi('در حال اجرا', _counts['in_progress'] ?? 0,
                          AppColors.level2),
                      const SizedBox(width: 10),
                      _kpi('بسته‌شده', _counts['closed'] ?? 0, AppColors.success),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _kpi('سطح ۱', _counts['l1'] ?? 0, AppColors.navyBlue,
                          small: true),
                      const SizedBox(width: 10),
                      _kpi('سطح ۲', _counts['l2'] ?? 0, AppColors.level2,
                          small: true),
                      const SizedBox(width: 10),
                      _kpi('سطح ۳', _counts['l3'] ?? 0, AppColors.level3,
                          small: true),
                    ],
                  ),
                  const SizedBox(height: 20),

                  Text('⏰ یادآورهای هوشمند — اقدامات عقب‌افتاده',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  if (_due.isEmpty)
                    const Card(
                        child: ListTile(
                      leading: Icon(Icons.check_circle, color: AppColors.success),
                      title: Text('هیچ اقدام عقب‌افتاده‌ای ندارید. آفرین!'),
                    ))
                  else
                    for (final d in _due)
                      Card(
                        color: d.isOverdue
                            ? AppColors.level3.withValues(alpha: .06)
                            : null,
                        child: ListTile(
                          leading: Icon(
                            d.isOverdue
                                ? Icons.notifications_active
                                : Icons.event_note,
                            color: d.isOverdue
                                ? AppColors.level3
                                : AppColors.level2,
                          ),
                          title: Text(d.title),
                          subtitle: Text(
                              '${d.problemTitle} | مهلت: ${PersianUtils.faDigits(d.dueDate)}'
                              ' | پیشرفت: ${PersianUtils.faDigits('${d.progress}')}٪'),
                          trailing: d.isOverdue
                              ? const Text('عقب‌افتاده',
                                  style: TextStyle(
                                      color: AppColors.level3,
                                      fontWeight: FontWeight.w800))
                              : const Text('امروز',
                                  style: TextStyle(
                                      color: AppColors.level2,
                                      fontWeight: FontWeight.w700)),
                        ),
                      ),
                ],
              ),
            ),
    );
  }

  Widget _kpi(String label, int value, Color color, {bool small = false}) =>
      Expanded(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(small ? 10 : 16),
            child: Column(
              children: [
                Text(PersianUtils.faDigits('$value'),
                    style: TextStyle(
                        fontSize: small ? 18 : 26,
                        fontWeight: FontWeight.w900,
                        color: color)),
                Text(label,
                    style:
                        const TextStyle(fontSize: 12, color: Colors.black54)),
              ],
            ),
          ),
        ),
      );
}
