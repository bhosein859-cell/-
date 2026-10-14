import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../level2/widgets/fishbone_widget.dart' show FishbonePainter;
import '../level3_provider.dart';
import '../widgets/decision_widgets.dart';

/// گام ۵ — ریشه‌یابی جامع: استخوان‌ماهی ۶M + چراهای چندشاخه + جدول KT
class Step5Screen extends ConsumerWidget {
  const Step5Screen({super.key});

  Future<void> _addWhy(BuildContext context, WidgetRef ref) async {
    final state = ref.read(level3WizardProvider);
    final text = TextEditingController();
    int? branch;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('چرایی جدید'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: text,
                  decoration: const InputDecoration(labelText: 'متن چرایی / پاسخ «چرا؟»')),
              const SizedBox(height: 12),
              DropdownButtonFormField<int?>(
                value: branch,
                decoration: const InputDecoration(labelText: 'شاخه (استخوان‌ماهی)'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('— بدون شاخه —')),
                  for (final f in state.fishbone.where((f) => f.parentId == null))
                    DropdownMenuItem(value: f.id, child: Text(f.title)),
                ],
                onChanged: (v) => setS(() => branch = v),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('انصراف')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('ثبت')),
          ],
        ),
      ),
    );
    if (ok == true && text.text.trim().isNotEmpty) {
      await ref.read(level3WizardProvider.notifier)
          .addWhyNodeL3(text.text.trim(), null, branch);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(level3WizardProvider);
    final notifier = ref.read(level3WizardProvider.notifier);
    final theme = Theme.of(context);
    final leaves = state.whysTree
        .where((w) => !state.whysTree.any((x) => x.parentId == w.nodeId))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ۱. استخوان‌ماهی
        Text('۱) استخوان‌ماهی (۶M)', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Container(
          height: 340,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.dividerColor),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CustomPaint(
              painter: FishbonePainter(
                  nodes: state.fishbone, problemTitle: state.title),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final cat in state.fishbone.where((f) => f.parentId == null))
              ActionChip(
                avatar: const Icon(Icons.add, size: 15),
                label: Text('علت در «${cat.title}»'),
                onPressed: () async {
                  final title = TextEditingController();
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text('علت جدید برای ${cat.title}'),
                      content: TextField(controller: title,
                          decoration: const InputDecoration(labelText: 'علت')),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('انصراف')),
                        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('ثبت')),
                      ],
                    ),
                  );
                  if (ok == true && title.text.trim().isNotEmpty) {
                    await notifier.addFishboneChildL3(cat.id!, title.text.trim());
                  }
                },
              ),
          ],
        ),
        const SizedBox(height: 16),

        // ۲. چراهای چندشاخه
        Text('۲) چراهای پنج‌گانه (چندشاخه)', style: theme.textTheme.titleMedium),
        const SizedBox(height: 6),
        OutlinedButton.icon(
          onPressed: () => _addWhy(context, ref),
          icon: const Icon(Icons.add),
          label: const Text('افزودن چرایی'),
        ),
        for (final w in state.whysTree)
          ListTile(
            dense: true,
            leading: Icon(Icons.subdirectory_arrow_left,
                color: w.parentId == null ? AppColors.navyBlue : AppColors.orange),
            title: Text(w.text),
            subtitle: leaves.contains(w)
                ? const Text('🎯 ریشه نهایی',
                    style: TextStyle(color: AppColors.orange, fontSize: 11))
                : null,
          ),
        const SizedBox(height: 16),

        // ۳. جدول KT
        Text('۳) تحلیل KT — هست / نیست', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        KtWidget(key: ValueKey(state.problemId)),
        const SizedBox(height: 16),

        // فهرست نهایی ریشه‌ها
        Text('فهرست نهایی ریشه‌ها', style: theme.textTheme.titleMedium),
        const SizedBox(height: 6),
        if (leaves.isEmpty)
          const Text('هنوز ریشه‌ای نهایی نشده؛ چرایی‌ها را تا رسیدن به علت اصلی ادامه دهید.')
        else
          for (final l in leaves)
            Row(children: [
              const Icon(Icons.flag, size: 16, color: AppColors.level3),
              const SizedBox(width: 6),
              Expanded(child: Text(l.text)),
            ]),
      ],
    );
  }
}

/// گام ۶ — طراحی راه‌حل: طوفان فکری + ماتریس وزنی Pugh + تحلیل ریسک
class Step6Screen extends ConsumerWidget {
  const Step6Screen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(level3WizardProvider);
    final best = state.bestPughSolution;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('۱) طوفان فکری آفلاین', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        const BrainstormWidget(),
        const Divider(height: 30),

        Text('۲) ماتریس تصمیم‌گیری وزنی Pugh', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        PughWidget(key: ValueKey(state.problemId)),
        const Divider(height: 30),

        Text('۳) تحلیل ریسک${best != null ? ' راه‌حل «$best»' : ''}',
            style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        const RiskWidget(),
      ],
    );
  }
}
