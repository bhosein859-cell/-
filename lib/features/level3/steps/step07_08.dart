import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/persian_utils.dart';
import '../../../core/utils/statistics.dart';
import '../../../data/models/level3_models.dart';
import '../level3_provider.dart';
import '../level3_state.dart';

/// گام ۷ — اجرای آزمایشی (Pilot) با آزمون معناداری آماری
class Step7Screen extends ConsumerStatefulWidget {
  const Step7Screen({super.key});

  @override
  ConsumerState<Step7Screen> createState() => _Step7ScreenState();
}

class _Step7ScreenState extends ConsumerState<Step7Screen> {
  final _note = TextEditingController();
  final _before = TextEditingController();
  final _after = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    _before.dispose();
    _after.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final b = double.tryParse(_before.text);
    final a = double.tryParse(_after.text);
    if (b == null || a == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('مقادیر قبل و بعد باید عدد باشند.')));
      return;
    }
    await ref.read(level3WizardProvider.notifier).addPilot(PilotResult(
          problemId: ref.read(level3WizardProvider).problemId!,
          date: DateTime.now(),
          before: b,
          after: a,
          statNote: _note.text,
        ));
    _before.clear();
    _after.clear();
    _note.clear();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(level3WizardProvider);
    final theme = Theme.of(context);
    final beforeList = state.pilots.map((p) => p.before).toList();
    final afterList = state.pilots.map((p) => p.after).toList();
    double? t;
    if (beforeList.length >= 2 && afterList.length >= 2) {
      t = Stats.welchT(beforeList, afterList).t;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'راه‌حل را در مقیاس کوچک اجرا و با داده‌ی قبل/بعد مقایسه کنید؛ '
          'آزمون آماری معناداری تفاوت را به‌صورت خودکار محاسبه می‌کند.',
          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.black54),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: TextField(controller: _before,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'مقدار قبل'))),
            const SizedBox(width: 8),
            Expanded(child: TextField(controller: _after,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'مقدار بعد'))),
            const SizedBox(width: 8),
            Expanded(child: TextField(controller: _note,
                decoration: const InputDecoration(labelText: 'یادداشت'))),
            const SizedBox(width: 8),
            FilledButton.icon(onPressed: _add,
                icon: const Icon(Icons.add), label: const Text('ثبت نمونه')),
          ],
        ),
        const SizedBox(height: 12),
        for (final p in state.pilots)
          ListTile(
            dense: true,
            leading: const Icon(Icons.science, size: 18),
            title: Text('${PersianUtils.faDigits(p.before.toStringAsFixed(2))} ← '
                '${PersianUtils.faDigits(p.after.toStringAsFixed(2))}'
                ' (${(p.statNote ?? '').isEmpty ? 'بدون یادداشت' : p.statNote})'),
            subtitle: Text(p.date.toIso8601String().substring(0, 10)),
            trailing: Icon(
              p.after < p.before ? Icons.trending_down : Icons.trending_up,
              color: p.after < p.before ? AppColors.success : AppColors.level3,
            ),
          ),
        if (t != null)
          Container(
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.navyBlue.withValues(alpha: .06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'آزمون ولچ (Welch t-test): t = ${PersianUtils.faDigits(t.toStringAsFixed(2))}'
              '${t.abs() >= 2 ? ' — تفاوت معنادار است ✓ (|t|≥۲)' : ' — هنوز معنادار نیست؛ نمونه بیشتری ثبت کنید.'}',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
      ],
    );
  }
}

/// گام ۸ — هزینه کیفیت (COPQ) + ROI + تایید مدیر مالی
class Step8Screen extends ConsumerStatefulWidget {
  const Step8Screen({super.key});

  @override
  ConsumerState<Step8Screen> createState() => _Step8ScreenState();
}

class _Step8ScreenState extends ConsumerState<Step8Screen> {
  final Map<String, Map<String, TextEditingController>> _rows = {};
  final _investment = TextEditingController();
  bool _initialized = false;

  void _init(Level3State state) {
    if (_initialized) return;
    _initialized = true;
    for (final key in CopqRow.faCategories.keys) {
      _rows[key] = {
        'before': TextEditingController(),
        'after': TextEditingController(),
      };
    }
    for (final r in state.copq) {
      if (_rows.containsKey(r.category)) {
        _rows[r.category]!['before']!.text = r.before.toStringAsFixed(0);
        _rows[r.category]!['after']!.text = r.after.toStringAsFixed(0);
      }
    }
    _investment.text =
        state.investment > 0 ? state.investment.toStringAsFixed(0) : '';
  }

  @override
  void dispose() {
    for (final r in _rows.values) {
      r.values.forEach((c) => c.dispose());
    }
    _investment.dispose();
    super.dispose();
  }

  void _save() {
    final rows = <CopqRow>[];
    for (final e in _rows.entries) {
      final b = double.tryParse(e.value['before']!.text) ?? 0;
      final a = double.tryParse(e.value['after']!.text) ?? 0;
      if (b > 0 || a > 0) {
        rows.add(CopqRow(
          problemId: ref.read(level3WizardProvider).problemId!,
          category: e.key,
          before: b,
          after: a,
        ));
      }
    }
    ref.read(level3WizardProvider.notifier).saveCopq(rows,
        investment: double.tryParse(_investment.text) ?? 0);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(level3WizardProvider);
    final notifier = ref.read(level3WizardProvider.notifier);
    final theme = Theme.of(context);
    _init(state);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'هزینه‌ی کیفیت را در چهار دسته قبل و بعد از حل مسئله وارد کنید؛ '
          'صرفه‌جویی و بازگشت سرمایه به‌صورت خودکار محاسبه می‌شود.',
          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.black54),
        ),
        const SizedBox(height: 12),
        for (final e in CopqRow.faCategories.entries) ...[
          Text(e.value, style: const TextStyle(fontWeight: FontWeight.w700)),
          Row(
            children: [
              Expanded(child: TextField(
                  controller: _rows[e.key]!['before'],
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'هزینه قبل'))),
              const SizedBox(width: 8),
              Expanded(child: TextField(
                  controller: _rows[e.key]!['after'],
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'هزینه بعد'))),
            ],
          ),
          const SizedBox(height: 10),
        ],
        TextField(
          controller: _investment,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
              labelText: 'سرمایه‌گذاری برای اجرای راه‌حل'),
        ),
        const SizedBox(height: 10),
        FilledButton.icon(onPressed: _save,
            icon: const Icon(Icons.calculate), label: const Text('محاسبه و ذخیره')),
        const SizedBox(height: 12),

        // نتایج
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                _kv('جمع هزینه قبل', PersianUtils.faDigits(state.copqBefore.toStringAsFixed(0))),
                _kv('جمع هزینه بعد', PersianUtils.faDigits(state.copqAfter.toStringAsFixed(0))),
                _kv('صرفه‌جویی', PersianUtils.faDigits(state.savings.toStringAsFixed(0)),
                    color: AppColors.success),
                _kv('بازگشت سرمایه (ROI)', PersianUtils.faDigits('${state.roi.toStringAsFixed(0)}٪'),
                    color: state.roi >= 0 ? AppColors.success : AppColors.level3),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),

        // تایید مالی
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: state.financeApproval
                ? AppColors.success.withValues(alpha: .08)
                : AppColors.orange.withValues(alpha: .06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: state.financeApproval ? AppColors.success : AppColors.orange),
          ),
          child: Row(
            children: [
              Icon(
                state.financeApproval ? Icons.verified : Icons.account_balance,
                color: state.financeApproval ? AppColors.success : AppColors.orange,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  state.financeApproval
                      ? 'تایید مدیر مالی ثبت شد ✓'
                      : 'برای ادامه به گام بعد، تایید مدیر مالی لازم است.',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
          FilledButton.tonal(
                onPressed: () => notifier.setFinanceApproval(!state.financeApproval),
                child: Text(state.financeApproval ? 'لغو تایید' : 'تایید مدیر مالی'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _kv(String k, String v, {Color? color}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Expanded(child: Text(k)),
            Text(v, style: TextStyle(fontWeight: FontWeight.w900, color: color)),
          ],
        ),
      );
}
