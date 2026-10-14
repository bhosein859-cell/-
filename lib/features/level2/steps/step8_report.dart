import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../services/excel_exporter.dart';
import '../../../services/word_report_l2.dart';
import '../level2_provider.dart';

/// گام ۸: گزارش‌گیری نهایی — خروجی Word چندصفحه‌ای (A3/PDCA) + Excel چهارشیته
/// و بستن مسئله.
class Step8Report extends ConsumerWidget {
  const Step8Report({super.key});

  void _snack(BuildContext context, String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _exportWord(BuildContext context, WidgetRef ref) async {
    try {
      final state = ref.read(level2WizardProvider);
      final path = await WordReportL2().generate(state: state);
      if (context.mounted) _snack(context, 'گزارش Word ذخیره شد:\n$path');
    } catch (e) {
      if (context.mounted) _snack(context, 'خطا در ساخت گزارش Word: $e');
    }
  }

  Future<void> _exportExcel(BuildContext context, WidgetRef ref) async {
    try {
      final state = ref.read(level2WizardProvider);
      final path = await ExcelExporter().exportLevel2(state: state);
      if (context.mounted) _snack(context, 'فایل Excel ذخیره شد:\n$path');
    } catch (e) {
      if (context.mounted) _snack(context, 'خطا در ساخت فایل Excel: $e');
    }
  }

  Future<void> _close(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('بستن مسئله‌ی سطح ۲'),
        content: const Text('پس از بستن، مسئله در لیست پروژه‌ها با نشان سبز «انجام شده» ثبت می‌شود.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('انصراف')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('بستن مسئله')),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(level2WizardProvider.notifier).closeProblem();
      if (context.mounted) {
        _snack(context, '🎉 مسئله بسته شد و با نشان سبز «انجام شده» ثبت گردید.');
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(level2WizardProvider);
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('گزارش‌گیری نهایی',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text('گزارش A3/PDCA به‌صورت خودکار از داده‌های هشت گام ساخته می‌شود.',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              const SizedBox(height: 20),

              // خلاصه‌ی آمادی گزارش
              _SummaryRow('تعریف 5W2H', state.def.what.isNotEmpty),
              _SummaryRow('تیم حل مسئله (${state.team.length} عضو)', state.team.isNotEmpty),
              _SummaryRow('شاخص‌های پایه (${state.kpis.length})', state.kpis.isNotEmpty),
              _SummaryRow('استخوان‌ماهی (${state.fishbone.where((n) => !n.isCategory).length} علت)',
                  state.fishbone.any((n) => !n.isCategory)),
              _SummaryRow('پارتو (${state.pareto.length} علت)', state.pareto.isNotEmpty),
              _SummaryRow('درخت ۵ چرا (${state.whysTree.length} گره)', state.whysTree.isNotEmpty),
              _SummaryRow('اقدامات 5W2H (${state.actions.length})', state.actions.isNotEmpty),
              _SummaryRow('گانت چارت (${state.gantt.length} نوار)', state.gantt.isNotEmpty),
              _SummaryRow('استانداردسازی (SOP)', state.sopText.isNotEmpty),
              const SizedBox(height: 24),

              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  FilledButton.icon(
                    onPressed: () => _exportWord(context, ref),
                    icon: const Icon(Icons.description),
                    label: const Text('خروجی Word چندصفحه‌ای'),
                    style: FilledButton.styleFrom(
                        backgroundColor: AppColors.navyBlue,
                        minimumSize: const Size(210, 52)),
                  ),
                  FilledButton.icon(
                    onPressed: () => _exportExcel(context, ref),
                    icon: const Icon(Icons.table_chart),
                    label: const Text('خروجی Excel (۴ شیت)'),
                    style: FilledButton.styleFrom(
                        backgroundColor: AppColors.success,
                        minimumSize: const Size(210, 52)),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _close(context, ref),
                    icon: const Icon(Icons.lock_open),
                    label: const Text('بستن مسئله'),
                    style: OutlinedButton.styleFrom(minimumSize: const Size(170, 52)),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow(this.label, this.done);
  final String label;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(done ? Icons.check_circle : Icons.radio_button_unchecked,
              size: 18, color: done ? AppColors.success : theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 10),
          Text(label, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}
