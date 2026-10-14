import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/persian_utils.dart';
import '../level2_provider.dart';

/// گام ۵: اجرا — ثبت درصد تکمیل هر اقدام توسط مسئول + موانع و راه‌حل‌های موقت.
class Step5Execution extends ConsumerWidget {
  const Step5Execution({super.key});

  Future<void> _addObstacle(BuildContext context, WidgetRef ref, int actionId) async {
    final obstacle = TextEditingController();
    final workaround = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ثبت مانع'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: obstacle, decoration: const InputDecoration(labelText: 'شرح مانع')),
            const SizedBox(height: 10),
            TextField(controller: workaround,
                decoration: const InputDecoration(labelText: 'راه‌حل موقت (اختیاری)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('انصراف')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('ثبت')),
        ],
      ),
    );
    if (ok == true && obstacle.text.trim().isNotEmpty) {
      await ref
          .read(level2WizardProvider.notifier)
          .addObstacle(actionId, obstacle.text.trim(), workaround.text.trim());
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(level2WizardProvider);
    final notifier = ref.read(level2WizardProvider.notifier);
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('اجرا — ثبت پیشرفت توسط مسئول اقدام',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Text('درصد تکمیل هر اقدام را به‌روزرسانی کنید؛ ذخیره خودکار است.',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 16),
        if (state.actions.isEmpty)
          const Text('اقدامی از گام قبل موجود نیست.'),
        for (final a in state.actions)
          Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: theme.dividerColor.withValues(alpha: .6)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        a.metadata['what']?.toString() ?? a.title,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    Text(
                      '٪${PersianUtils.faDigits('${a.progress}')}',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: a.progress >= 100 ? AppColors.success : AppColors.orange,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: a.progress.toDouble(),
                  divisions: 20,
                  min: 0,
                  max: 100,
                  label: '٪${PersianUtils.faDigits('${a.progress}')}',
                  activeColor: a.progress >= 100 ? AppColors.success : AppColors.orange,
                  onChanged: (v) => notifier.setActionProgress(a.id!, v.round()),
                ),
                // موانع ثبت‌شده
                for (final ob in (a.metadata['obstacles'] as List? ?? []))
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.warning_amber_rounded,
                            size: 16, color: AppColors.orange),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'مانع: ${ob['text']}'
                            '${(ob['workaround']?.toString().isEmpty ?? true) ? '' : ' | راه‌حل موقت: ${ob['workaround']}'}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => _addObstacle(context, ref, a.id!),
                    icon: const Icon(Icons.report_problem_outlined, size: 17),
                    label: const Text('ثبت مانع'),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
