import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/persian_utils.dart';
import '../../../data/models/level3_models.dart';
import '../level3_provider.dart';

/// طوفان فکری آفلاین — ثبت ایده بدون قضاوت
class BrainstormWidget extends ConsumerStatefulWidget {
  const BrainstormWidget({super.key});

  @override
  ConsumerState<BrainstormWidget> createState() => _BrainstormWidgetState();
}

class _BrainstormWidgetState extends ConsumerState<BrainstormWidget> {
  final _idea = TextEditingController();

  @override
  void dispose() {
    _idea.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(level3WizardProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _idea,
                decoration: const InputDecoration(
                    hintText: 'ایده‌ی جدید… (در طوفان فکری قضاوت ممنوع است)'),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: () {
                if (_idea.text.trim().isEmpty) return;
                ref.read(level3WizardProvider.notifier).addIdea(_idea.text.trim());
                _idea.clear();
              },
              child: const Text('ثبت ایده'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final idea in state.ideas)
              Chip(
                avatar: const Icon(Icons.lightbulb_outline, size: 15, color: AppColors.orange),
                label: Text(idea),
              ),
            if (state.ideas.isEmpty) const Text('هنوز ایده‌ای ثبت نشده است.'),
          ],
        ),
        if (state.ideas.isNotEmpty) ...[
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () =>
                ref.read(level3WizardProvider.notifier).promoteIdeasToPugh(),
            icon: const Icon(Icons.grid_on),
            label: const Text('انتقال ایده‌ها به ماتریس Pugh'),
          ),
        ],
      ],
    );
  }
}

/// ماتریس تصمیم‌گیری Pugh — معیارهای وزن‌دار + امتیازدهی خودکار
class PughWidget extends ConsumerWidget {
  const PughWidget({super.key});

  static const List<Map<String, String>> _criteria = [
    {'key': 'cost', 'fa': 'هزینه'},
    {'key': 'time', 'fa': 'زمان'},
    {'key': 'effectiveness', 'fa': 'اثربخشی'},
    {'key': 'risk', 'fa': 'ریسک (کم‌ریسکی)'},
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(level3WizardProvider);
    final notifier = ref.read(level3WizardProvider.notifier);
    final totals = state.pughTotals();
    final best = state.bestPughSolution;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // وزن معیارها
        Wrap(
          spacing: 18,
          runSpacing: 4,
          children: [
            for (final c in _criteria)
              SizedBox(
                width: 190,
                child: Row(
                  children: [
                    Text(c['fa']!, style: const TextStyle(fontSize: 12.5)),
                    Expanded(
                      child: Slider(
                        min: 1,
                        max: 10,
                        divisions: 9,
                        value: (state.pughWeights[c['key']] ?? 5).toDouble(),
                        onChanged: (v) =>
                            notifier.setPughWeight(c['key']!, v.round()),
                      ),
                    ),
                    Text(PersianUtils.faDigits('${state.pughWeights[c['key']]}'),
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),

        if (state.pughSolutions.isEmpty)
          const Text('راه‌حلی در ماتریس نیست؛ ابتدا در طوفان فکری ایده‌ها را منتقل کنید.'),

        // جدول امتیازها
        if (state.pughSolutions.isNotEmpty)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: [
                const DataColumn(label: Text('راه‌حل')),
                for (final c in _criteria)
                  DataColumn(label: Text(c['fa']!)),
                const DataColumn(label: Text('مجموع وزنی')),
              ],
              rows: [
                for (final sol in state.pughSolutions)
                  DataRow(
                    color: WidgetStatePropertyAll(
                        sol == best ? AppColors.success.withValues(alpha: .1) : null),
                    cells: [
                      DataCell(Text(sol,
                          style: TextStyle(
                              fontWeight: sol == best ? FontWeight.w900 : FontWeight.w500))),
                      for (final c in _criteria)
                        DataCell(DropdownButton<int>(
                          value: state.pughCells
                                  .where((x) => x.solution == sol && x.criterion == c['key'])
                                  .map((x) => x.score)
                                  .firstOrNullSafe2() ??
                              3,
                          underline: const SizedBox.shrink(),
                          items: [
                            for (var s = 1; s <= 5; s++)
                              DropdownMenuItem(
                                  value: s, child: Text(PersianUtils.faDigits('$s'))),
                          ],
                          onChanged: (v) => notifier.setPughScore(
                              sol, c['key']!, v ?? 3),
                        )),
                      DataCell(Text(
                        PersianUtils.faDigits('${totals[sol] ?? 0}'),
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      )),
                    ],
                  ),
              ],
            ),
          ),
        if (best != null)
          Container(
            margin: const EdgeInsets.only(top: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.success.withValues(alpha: .5)),
            ),
            child: Text(
              '🏆 راه‌حل برتر: «$best» با امتیاز ${PersianUtils.faDigits('${totals[best]}')}',
              style: const TextStyle(
                  fontWeight: FontWeight.w900, color: AppColors.success),
            ),
          ),
      ],
    );
  }
}

extension _First2<T> on Iterable<T> {
  T? firstOrNullSafe2() => isEmpty ? null : first;
}

/// تحلیل ریسک راه‌حل منتخب
class RiskWidget extends ConsumerWidget {
  const RiskWidget({super.key});

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final risk = TextEditingController();
    final mitigation = TextEditingController();
    int prob = 3, impact = 3;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('ریسک راه‌حل'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: risk, decoration: const InputDecoration(labelText: 'شرح ریسک')),
              TextField(controller: mitigation, decoration: const InputDecoration(labelText: 'راه‌حل کاهشی')),
              Row(children: [
                Expanded(child: Text('احتمال: ${PersianUtils.faDigits('$prob')}')),
                Expanded(child: Slider(min: 1, max: 5, divisions: 4, value: prob.toDouble(),
                    onChanged: (v) => setS(() => prob = v.round()))),
              ]),
              Row(children: [
                Expanded(child: Text('اثر: ${PersianUtils.faDigits('$impact')}')),
                Expanded(child: Slider(min: 1, max: 5, divisions: 4, value: impact.toDouble(),
                    onChanged: (v) => setS(() => impact = v.round()))),
              ]),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('انصراف')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('ثبت')),
          ],
        ),
      ),
    );
    if (ok == true && risk.text.trim().isNotEmpty) {
      await ref.read(level3WizardProvider.notifier).addRisk({
        'risk': risk.text.trim(),
        'mitigation': mitigation.text,
        'prob': prob,
        'impact': impact,
        'score': prob * impact,
      });
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(level3WizardProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OutlinedButton.icon(
          onPressed: () => _add(context, ref),
          icon: const Icon(Icons.shield_outlined),
          label: const Text('افزودن ریسک'),
        ),
        const SizedBox(height: 8),
        for (final r in state.risks)
          Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (r['score'] as int? ?? 0) >= 15
                  ? AppColors.level3.withValues(alpha: .08)
                  : AppColors.navyBlue.withValues(alpha: .05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '⚠ ${r['risk']} — امتیاز ریسک: ${PersianUtils.faDigits('${r['score']}')}'
              ' | کاهش: ${r['mitigation']}',
              style: const TextStyle(fontSize: 12.5),
            ),
          ),
        if (state.risks.isEmpty) const Text('ریسکی ثبت نشده است.'),
      ],
    );
  }
}

/// جدول چهارخانه‌ای KT — Is / Is Not
class KtWidget extends ConsumerStatefulWidget {
  const KtWidget({super.key});

  @override
  ConsumerState<KtWidget> createState() => _KtWidgetState();
}

class _KtWidgetState extends ConsumerState<KtWidget> {
  late final Map<String, TextEditingController> _c;

  @override
  void initState() {
    super.initState();
    final kt = ref.read(level3WizardProvider).kt;
    _c = {
      for (final e in kt.toJson().entries)
        e.key: TextEditingController(text: e.value as String),
    };
  }

  @override
  void dispose() {
    _c.values.forEach((c) => c.dispose());
    super.dispose();
  }

  void _save() {
    ref.read(level3WizardProvider.notifier).saveKt(KtAnalysis.fromJson(
        {for (final e in _c.entries) e.key: e.value.text}));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const rows = [
      ['is_what', 'is_not_what', 'چه چیزی هست / نیست'],
      ['is_where', 'is_not_where', 'کجا هست / نیست'],
      ['is_when', 'is_not_when', 'چه زمانی هست / نیست'],
      ['is_who', 'is_not_who', 'چه کسی درگیر هست / نیست'],
    ];
    return Table(
      border: TableBorder.all(color: theme.dividerColor.withValues(alpha: .6)),
      columnWidths: const {
        0: FlexColumnWidth(1),
        1: FlexColumnWidth(1),
        2: FlexColumnWidth(.8),
      },
      children: [
        TableRow(
          decoration: BoxDecoration(color: AppColors.navyBlue.withValues(alpha: .08)),
          children: const [
            TableCell(child: Padding(padding: EdgeInsets.all(8), child: Text('هست (Is)', style: TextStyle(fontWeight: FontWeight.w800)))),
            TableCell(child: Padding(padding: EdgeInsets.all(8), child: Text('نیست (Is Not)', style: TextStyle(fontWeight: FontWeight.w800)))),
            TableCell(child: Padding(padding: EdgeInsets.all(8), child: Text('بُعد', style: TextStyle(fontWeight: FontWeight.w800)))),
          ],
        ),
        for (final r in rows)
          TableRow(
            children: [
              TableCell(child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: TextField(controller: _c[r[0]], onChanged: (_) => _save(), maxLines: 2))),
              TableCell(child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: TextField(controller: _c[r[1]], onChanged: (_) => _save(), maxLines: 2))),
              TableCell(child: Center(child: Text(r[2], style: const TextStyle(fontSize: 12)))),
            ],
          ),
      ],
    );
  }
}
