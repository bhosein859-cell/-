import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/persian_utils.dart';
import '../../data/database/database_helper.dart';

/// ═══════════════════════════════════════════════════════════════
/// نمای تقویم — نمایش مهلت اقدامات روی تقویم میلادی (بدون وابستگی
/// خارجی؛ تقویم شمسی با برچسب‌های فارسی روزها). کلیک روی هر روز،
/// لیست اقدامات آن روز را نشان می‌دهد.
/// ═══════════════════════════════════════════════════════════════
class CalendarViewScreen extends ConsumerStatefulWidget {
  const CalendarViewScreen({super.key});

  @override
  ConsumerState<CalendarViewScreen> createState() => _CalendarViewScreenState();
}

class _CalendarViewScreenState extends ConsumerState<CalendarViewScreen> {
  late DateTime _month;
  Map<String, List<_DueItem>> _items = {};
  bool _loading = true;

  static const List<String> _weekDays = [
    'ش', 'ی', 'د', 'س', 'چ', 'پ', 'ج',
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month, 1);
    _load();
  }

  Future<void> _load() async {
    final db = await ref.read(databaseProvider).database;
    final rows = await db.rawQuery('''
      SELECT a.title, a.due_date, a.status, p.title AS problem
      FROM actions a JOIN problems p ON p.id = a.problem_id
      WHERE a.due_date IS NOT NULL AND p.is_archived = 0
    ''');
    final acc = <String, List<_DueItem>>{};
    for (final r in rows) {
      final d = (r['due_date'] as String? ?? '').substring(0, 10);
      if (d.isEmpty) continue;
      (acc[d] ??= []).add(_DueItem(
        title: r['title'] as String? ?? '',
        problem: r['problem'] as String? ?? '',
        done: r['status'] == 'done',
      ));
    }
    setState(() {
      _items = acc;
      _loading = false;
    });
  }

  void _shiftMonth(int delta) {
    setState(() {
      _month = DateTime(_month.year, _month.month + delta, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final first = _month;
    // شنبه = اولین روز هفته در ایران؛ میلادی: یکشنبه=7
    final weekdayOffset = (first.weekday + 1) % 7;
    final daysInMonth = DateTime(first.year, first.month + 1, 0).day;
    final today = DateTime.now();
    final todayKey = today.toIso8601String().substring(0, 10);

    return Scaffold(
      appBar: AppBar(title: const Text('📅 تقویم مهلت‌ها')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // ── ناوبری ماه ──
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                          icon: const Icon(Icons.chevron_right),
                          onPressed: () => _shiftMonth(-1)),
                      Text(
                        PersianUtils.faDigits(
                            '${_month.year}/${_month.month.toString().padLeft(2, '0')}'),
                        style: const TextStyle(
                            fontWeight: FontWeight.w900, fontSize: 16),
                      ),
                      IconButton(
                          icon: const Icon(Icons.chevron_left),
                          onPressed: () => _shiftMonth(1)),
                    ],
                  ),
                ),
                // ── سرستون روزها ──
                Row(
                  children: [
                    for (final w in _weekDays)
                      Expanded(
                        child: Center(
                          child: Text(w,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: Colors.black54)),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                // ── شبکه روزها ──
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(8),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7,
                      childAspectRatio: 0.9,
                    ),
                    itemCount: weekdayOffset + daysInMonth,
                    itemBuilder: (context, i) {
                      if (i < weekdayOffset) {
                        return const SizedBox.shrink();
                      }
                      final day = i - weekdayOffset + 1;
                      final key =
                          '${_month.year}-${_month.month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
                      final items = _items[key] ?? const <_DueItem>[];
                      final isToday = key == todayKey;
                      return GestureDetector(
                        onTap: items.isEmpty
                            ? null
                            : () => _showDay(key, items),
                        child: Container(
                          margin: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: isToday
                                ? AppColors.navyBlue.withValues(alpha: .08)
                                : null,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isToday
                                  ? AppColors.navyBlue
                                  : items.isNotEmpty
                                      ? AppColors.orange.withValues(alpha: .6)
                                      : Colors.transparent,
                              width: isToday ? 2 : 1.4,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(PersianUtils.faDigits('$day'),
                                  style: TextStyle(
                                    fontWeight: isToday
                                        ? FontWeight.w900
                                        : FontWeight.w500,
                                  )),
                              if (items.isNotEmpty)
                                Container(
                                  margin: const EdgeInsets.only(top: 3),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: items.any((x) => !x.done)
                                        ? AppColors.level3
                                        : AppColors.success,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    PersianUtils.faDigits('${items.length}'),
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 9),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  void _showDay(String key, List<_DueItem> items) {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text('مهلت‌های ${PersianUtils.faDigits(key)}',
                  style: const TextStyle(fontWeight: FontWeight.w900)),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final it in items)
                    ListTile(
                      dense: true,
                      leading: Icon(
                        it.done ? Icons.check_circle : Icons.schedule,
                        color:
                            it.done ? AppColors.success : AppColors.level2,
                      ),
                      title: Text(it.title),
                      subtitle: Text(it.problem),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DueItem {
  const _DueItem({
    required this.title,
    required this.problem,
    required this.done,
  });

  final String title;
  final String problem;
  final bool done;
}
