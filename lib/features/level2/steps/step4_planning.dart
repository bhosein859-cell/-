import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/persian_utils.dart';
import '../level2_provider.dart';
import '../widgets/gantt_widget.dart';

/// گام ۴: برنامه‌ریزی اقدام — جدول اقدامات 5W2H + گانت چارت.
class Step4Planning extends ConsumerWidget {
  const Step4Planning({super.key});

  Future<void> _addAction(BuildContext context, WidgetRef ref) async {
    final what = TextEditingController();
    final who = TextEditingController();
    final where = TextEditingController();
    final why = TextEditingController();
    final how = TextEditingController();
    final howMuch = TextEditingController();
    DateTime start = DateTime.now();
    DateTime end = DateTime.now().add(const Duration(days: 2));

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('اقدام جدید (5W2H)'),
          content: SizedBox(
            width: 420,
            child: ListView(
              shrinkWrap: true,
              children: [
                TextField(controller: what, decoration: const InputDecoration(labelText: 'چه کاری؟ (What) *')),
                TextField(controller: who, decoration: const InputDecoration(labelText: 'چه کسی؟ (Who) — مسئول اقدام')),
                TextField(controller: where, decoration: const InputDecoration(labelText: 'کجا؟ (Where)')),
                TextField(controller: why, decoration: const InputDecoration(labelText: 'چرا؟ (Why)')),
                TextField(controller: how, decoration: const InputDecoration(labelText: 'چگونه؟ (How)')),
                TextField(controller: howMuch, decoration: const InputDecoration(labelText: 'چقدر؟ (How Much) — هزینه/منابع')),
                Row(
                  children: [
                    Expanded(
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text('شروع: ${PersianUtils.faDate(start)}', style: const TextStyle(fontSize: 13)),
                        trailing: const Icon(Icons.calendar_month, size: 18),
                        onTap: () async {
                          final d = await showDatePicker(
                              context: ctx,
                              initialDate: start,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2035));
                          if (d != null) setS(() => start = d);
                        },
                      ),
                    ),
                    Expanded(
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text('پایان: ${PersianUtils.faDate(end)}', style: const TextStyle(fontSize: 13)),
                        trailing: const Icon(Icons.calendar_month, size: 18),
                        onTap: () async {
                          final d = await showDatePicker(
                              context: ctx,
                              initialDate: end,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2035));
                          if (d != null) setS(() => end = d);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('انصراف')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('ثبت اقدام')),
          ],
        ),
      ),
    );
    if (ok == true && what.text.trim().isNotEmpty) {
      await ref.read(level2WizardProvider.notifier).addAction({
        'what': what.text.trim(),
        'who': who.text,
        'where': where.text,
        'why': why.text,
        'how': how.text,
        'how_much': howMuch.text,
        'start': start.toIso8601String(),
        'end': end.toIso8601String(),
      });
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(level2WizardProvider);
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            Text('جدول اقدامات 5W2H',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            const Spacer(),
            FilledButton.icon(
                onPressed: () => _addAction(context, ref),
                icon: const Icon(Icons.add_task),
                label: const Text('اقدام جدید')),
          ],
        ),
        const SizedBox(height: 14),

        // جدول اقدامات (اسکرول افقی برای ستون‌های 5W2H)
        if (state.actions.isNotEmpty)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStatePropertyAll(
                  theme.colorScheme.primary.withValues(alpha: .08)),
              columns: const [
                DataColumn(label: Text('چه کاری؟')),
                DataColumn(label: Text('چه کسی؟')),
                DataColumn(label: Text('کجا؟')),
                DataColumn(label: Text('چرا؟')),
                DataColumn(label: Text('چگونه؟')),
                DataColumn(label: Text('چقدر؟')),
                DataColumn(label: Text('بازه')),
                DataColumn(label: Text('وضعیت')),
              ],
              rows: [
                for (final a in state.actions)
                  DataRow(cells: [
                    DataCell(Text(a.metadata['what']?.toString() ?? a.title)),
                    DataCell(Text(a.metadata['who']?.toString().isEmpty ?? true
                        ? '—'
                        : a.metadata['who'].toString())),
                    DataCell(Text(a.metadata['where']?.toString() ?? '—')),
                    DataCell(Text(a.metadata['why']?.toString() ?? '—')),
                    DataCell(Text(a.metadata['how']?.toString() ?? '—')),
                    DataCell(Text(a.metadata['how_much']?.toString() ?? '—')),
                    DataCell(Text(
                        '${_d(a.metadata['start'])} ← ${_d(a.metadata['end'])}')),
                    DataCell(Text(a.statusFa)),
                  ]),
              ],
            ),
          ),
        if (state.actions.isEmpty)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: theme.dividerColor.withValues(alpha: .6)),
            ),
            child: const Text('اقدامی تعریف نشده است؛ با «اقدام جدید» جدول 5W2H را پر کنید.'),
          ),
        const SizedBox(height: 28),

        Text('گانت چارت زمان‌بندی',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        const GanttWidget(),
      ],
    );
  }

  String _d(dynamic iso) {
    final dt = DateTime.tryParse(iso?.toString() ?? '');
    return dt == null ? '—' : PersianUtils.faDate(dt);
  }
}
