import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/persian_utils.dart';
import '../../../data/models/level3_models.dart';
import '../../../services/excel_exporter_l3.dart';
import '../../../services/pdf_report_builder.dart';
import '../../../services/word_report_l3.dart';
import '../level3_provider.dart';

/// گام ۱۱ — درس‌آموخته‌ها و انتقال به بانک دانش
class Step11Screen extends ConsumerStatefulWidget {
  const Step11Screen({super.key});

  @override
  ConsumerState<Step11Screen> createState() => _Step11ScreenState();
}

class _Step11ScreenState extends ConsumerState<Step11Screen> {
  final _lesson = TextEditingController();

  @override
  void dispose() {
    _lesson.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    if (_lesson.text.trim().isEmpty) return;
    var category = 'technical';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('دسته‌بندی درس‌آموخته'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile(
                title: const Text('فنی / فرایندی'),
                value: 'technical',
                groupValue: category,
                onChanged: (v) => setS(() => category = v!),
              ),
              RadioListTile(
                title: const Text('مدیریتی'),
                value: 'management',
                groupValue: category,
                onChanged: (v) => setS(() => category = v!),
              ),
              RadioListTile(
                title: const Text('رفتاری / تیمی'),
                value: 'behavioral',
                groupValue: category,
                onChanged: (v) => setS(() => category = v!),
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
    if (ok == true) {
      await ref.read(level3WizardProvider.notifier).addLesson(LessonLearned(
            problemId: ref.read(level3WizardProvider).problemId!,
            lesson: _lesson.text.trim(),
            category: category,
          ));
      _lesson.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(level3WizardProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'هر درس‌آموخته به بانک دانش منتقل می‌شود و رهنمودی برای '
          'پروژه‌های مشابه آینده خواهد بود.',
          style: TextStyle(color: Colors.black54),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(controller: _lesson,
                  decoration: const InputDecoration(
                      hintText: 'درس‌آموخته‌ی جدید… (مثلاً: قبل از پیلوت داده‌ی پایه جمع‌آوری شود)')),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(onPressed: _add,
                icon: const Icon(Icons.menu_book), label: const Text('ثبت')),
          ],
        ),
        const SizedBox(height: 12),
        for (final l in state.lessons)
          ListTile(
            dense: true,
            leading: const Icon(Icons.lightbulb_outline,
                size: 18, color: AppColors.orange),
            title: Text(l.lesson),
            subtitle: Text(l.categoryFa),
          ),
        if (state.lessons.isEmpty) const Text('هنوز درس‌آموخته‌ای ثبت نشده است.'),
      ],
    );
  }
}

/// گام ۱۲ — بستن پروژه: خروجی‌های نهایی، گیمیفیکیشن، تایید مدیر حامی
class Step12Screen extends ConsumerWidget {
  const Step12Screen({super.key});

  void _snack(BuildContext context, String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _exportWord(BuildContext context, WidgetRef ref) async {
    try {
      final path = await WordReportL3()
          .generate(state: ref.read(level3WizardProvider));
      if (context.mounted) _snack(context, 'گزارش جامع Word ذخیره شد:\n$path');
    } catch (e) {
      if (context.mounted) _snack(context, 'خطا در ساخت گزارش Word: $e');
    }
  }

  Future<void> _exportExcel(BuildContext context, WidgetRef ref) async {
    try {
      final path = await ExcelExporterL3()
          .exportLevel3(state: ref.read(level3WizardProvider));
      if (context.mounted) _snack(context, 'فایل Excel پنج‌شیته ذخیره شد:\n$path');
    } catch (e) {
      if (context.mounted) _snack(context, 'خطا در ساخت فایل Excel: $e');
    }
  }

  Future<void> _exportPdf(BuildContext context, WidgetRef ref) async {
    try {
      final path =
          await PdfReportBuilder.buildAndSave(ref.read(level3WizardProvider));
      if (context.mounted) _snack(context, 'نسخه‌ی بایگانی PDF ذخیره شد:\n$path');
    } catch (e) {
      if (context.mounted) _snack(context, 'خطا در ساخت گزارش PDF: $e');
    }
  }

  Future<void> _close(BuildContext context, WidgetRef ref) async {
    final state = ref.read(level3WizardProvider);
    if (!state.sponsorApproval) {
      _snack(context, 'برای بستن پروژه، تایید نهایی مدیر حامی لازم است.');
      return;
    }
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('بستن رسمی پروژه'),
        content: const Text(
          'با بستن پروژه:\n'
          '• وضعیت آن به «بسته شده» تغییر می‌کند،\n'
          '• درس‌آموخته‌ها و خلاصه به بانک دانش منتقل می‌شود،\n'
          '• امتیاز تیم محاسبه و ثبت می‌شود.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('انصراف')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('بستن پروژه')),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(level3WizardProvider.notifier).closeProject();
      if (context.mounted) {
        _snack(context, '🏆 پروژه بسته شد؛ امتیاز تیم: '
            '${PersianUtils.faDigits('${ref.read(level3WizardProvider).teamScore}')}');
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(level3WizardProvider);
    final notifier = ref.read(level3WizardProvider.notifier);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('خروجی‌های نهایی', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            FilledButton.icon(
              onPressed: () => _exportWord(context, ref),
              icon: const Icon(Icons.description_outlined),
              label: const Text('گزارش جامع Word'),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: AppColors.success),
              onPressed: () => _exportExcel(context, ref),
              icon: const Icon(Icons.grid_on_outlined),
              label: const Text('Excel پنج‌شیته'),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: AppColors.level3),
              onPressed: () => _exportPdf(context, ref),
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: const Text('بایگانی PDF'),
            ),
          ],
        ),
        const Divider(height: 28),

        // تایید مدیر حامی
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: state.sponsorApproval
                ? AppColors.success.withValues(alpha: .08)
                : AppColors.navyBlue.withValues(alpha: .05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: state.sponsorApproval
                    ? AppColors.success
                    : AppColors.navyBlue.withValues(alpha: .4)),
          ),
          child: Row(
            children: [
              Icon(state.sponsorApproval ? Icons.verified : Icons.admin_panel_settings_outlined,
                  color: state.sponsorApproval ? AppColors.success : AppColors.navyBlue),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  state.sponsorApproval
                      ? 'مدیر حامی پروژه را تایید نهایی کرد ✓'
                      : 'تایید نهایی مدیر حامی برای بستن پروژه الزامی است.',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              FilledButton.tonal(
                onPressed: () => notifier.setSponsorApproval(!state.sponsorApproval),
                child: Text(state.sponsorApproval ? 'لغو تایید' : 'تایید مدیر حامی'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // امتیاز تیم (پیش‌نمایش گیمیفیکیشن)
        Card(
          color: AppColors.navyBlue.withValues(alpha: .04),
          child: ListTile(
            leading: const Icon(Icons.emoji_events, color: AppColors.orange),
            title: const Text('امتیاز تیم',
                style: TextStyle(fontWeight: FontWeight.w800)),
            subtitle: Text(
                'پایه ۵۰ + هر درس‌آموخته ۵ + هر اقدام پیشنهادی بحرانی ۱۰ + '
                'تایید مهار ۱۰ + صرفه‌جویی مثبت ۲۰'),
            trailing: Text(
              PersianUtils.faDigits('${state.teamScore}'),
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.orange),
            ),
          ),
        ),
        const SizedBox(height: 14),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: state.sponsorApproval ? AppColors.success : Colors.grey,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          onPressed: () => _close(context, ref),
          icon: const Icon(Icons.flag),
          label: const Text('بستن رسمی پروژه',
              style: TextStyle(fontWeight: FontWeight.w900)),
        ),
      ],
    );
  }
}
