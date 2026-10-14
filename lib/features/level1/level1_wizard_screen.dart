import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/persian_utils.dart';
import '../../data/repositories/problem_repository.dart';
import '../../services/word_exporter.dart';
import 'level1_provider.dart';
import 'steps/step1_problem_form.dart';
import 'steps/step2_five_whys.dart';
import 'steps/step3_action_form.dart';
import 'steps/step4_verify_screen.dart';

/// ویزارد ۴ مرحله‌ای سطح ۱ (حل سریع).
///
/// - تمام‌صفحه؛ منوی کناری/پایینی اپ در حین ویزارد پنهان است.
/// - نشانگر پیشرفت «مرحله X از ۴» در بالا + دکمه‌های قبلی/بعدی در پایین.
/// - دکمه‌ی خروج با پنجره‌ی تاییدیه.
class Level1WizardScreen extends ConsumerStatefulWidget {
  const Level1WizardScreen({super.key});

  @override
  ConsumerState<Level1WizardScreen> createState() => _Level1WizardScreenState();
}

class _Level1WizardScreenState extends ConsumerState<Level1WizardScreen> {
  final PageController _pageController = PageController();

  static const List<String> _stepTitles = [
    'ثبت مشکل',
    'ریشه‌یابی سریع (۵ چرا)',
    'اقدام فوری',
    'بستن و تایید',
  ];

  @override
  void initState() {
    super.initState();
    // همگام‌سازی خودکار PageView با تغییر مرحله از هر نقطه‌ای
    // (دکمه‌های ناوبری یا بازگشت خودکار مرحله ۴ → ۲)
    ref.listenManual(level1WizardProvider, (prev, next) {
      if (prev?.step != next.step && _pageController.hasClients) {
        _pageController.animateToPage(
          next.step,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  // ── ناوبری مراحل ──

  Future<void> _next() async {
    final notifier = ref.read(level1WizardProvider.notifier);
    final state = ref.read(level1WizardProvider);
    if (state.busy) return;

    switch (state.step) {
      case 0:
        if (state.title.trim().isEmpty) {
          return _snack('لطفاً عنوان مشکل را وارد کنید.');
        }
        final err = await notifier.createProblem();
        if (err != null) return _snack(err);
        notifier.setStep(1);
      case 1:
        if (state.whys.first.trim().isEmpty) {
          return _snack('حداقل «چرا»ی اول را پاسخ دهید.');
        }
        final err = await notifier.saveWhys();
        if (err != null) return _snack(err);
        notifier.setStep(2);
      case 2:
        if (state.actionTitle.trim().isEmpty) {
          return _snack('شرح اقدام انجام‌شده را بنویسید.');
        }
        final err = await notifier.saveAction();
        if (err != null) return _snack(err);
        notifier.setStep(3);
    }
  }

  void _previous() {
    final step = ref.read(level1WizardProvider).step;
    if (step > 0) ref.read(level1WizardProvider.notifier).setStep(step - 1);
  }

  // ── خروج با تاییدیه ──

  Future<bool> _confirmExit() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('خروج از ویزارد؟'),
        content: const Text(
            'اگر اکنون خارج شوید، پیشرفت ذخیره‌نشده‌ی این مرحله از بین می‌رود.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ادامه می‌دهم'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.level3),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('خروج'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  // ── بستن مسئله و دیالوگ موفقیت ──

  Future<void> _closeProblem() async {
    final notifier = ref.read(level1WizardProvider.notifier);
    final err = await notifier.closeProblem();
    if (err != null) return _snack(err);
    if (mounted) _showSuccessDialog();
  }

  void _showSuccessDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircleAvatar(
              radius: 36,
              backgroundColor: AppColors.success,
              child: Icon(Icons.done, size: 40, color: Colors.white),
            ),
            const SizedBox(height: 16),
            const Text(
              'آفرین! مسئله بسته شد 🎉',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            const Text(
              'این مسئله در لیست «پروژه‌های فعال» با نشان سبز «انجام شده» نمایش داده می‌شود.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () async {
                  Navigator.pop(context);
                  await _exportWord();
                },
                icon: const Icon(Icons.description_outlined),
                label: const Text('خروجی گزارش Word'),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pop(context); // بستن دیالوگ
                  Navigator.pop(context); // خروج از ویزارد
                },
                child: const Text('بازگشت به برنامه'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// تولید گزارش Word سطح ۱ با درج نام سازنده
  Future<void> _exportWord() async {
    final state = ref.read(level1WizardProvider);
    final repo = ref.read(problemRepositoryProvider);
    final problemId = state.problemId;
    if (problemId == null) return;

    try {
      final problem = await repo.getProblem(problemId);
      if (problem == null) return _snack('مسئله یافت نشد.');
      final actions = await repo.actionsForProblem(problemId);
      final path = await WordExporter()
          .exportLevel1Report(problem: problem, actions: actions);
      _snack('گزارش Word ذخیره شد:\n$path');
    } catch (e) {
      _snack('خطا در ساخت گزارش Word: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(level1WizardProvider);
    final theme = Theme.of(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _confirmExit()) {
          if (mounted) Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          // در RTL این دکمه سمت راست قرار می‌گیرد
          leading: IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'خروج',
            onPressed: () async {
              if (await _confirmExit()) {
                if (mounted) Navigator.of(context).pop();
              }
            },
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('ویزارد حل سریع', style: TextStyle(fontSize: 17)),
              Text(
                'مرحله ${PersianUtils.faDigits('${state.step + 1}')} از ${PersianUtils.faDigits('4')} • ${_stepTitles[state.step]}',
                style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant, fontSize: 12),
              ),
            ],
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.all(10),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.level1.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'سطح ۱',
                  style: TextStyle(
                      color: AppColors.level1,
                      fontWeight: FontWeight.w800,
                      fontSize: 12),
                ),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            // نشانگر پیشرفت
            LinearProgressIndicator(
              value: (state.step + 1) / 4,
              backgroundColor: theme.dividerColor.withValues(alpha: .4),
              color: AppColors.orange,
              minHeight: 5,
            ),
            // صفحات چهارگانه — اسwipe غیرفعال تا اعتبارسنجی مراحل حفظ شود
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: const [
                  Step1ProblemForm(),
                  Step2FiveWhys(),
                  Step3ActionForm(),
                  Step4VerifyScreen(),
                ],
              ),
            ),
            // دکمه‌های ناوبری پایین
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Row(
                  children: [
                    if (state.step > 0)
                      OutlinedButton.icon(
                        onPressed: state.busy ? null : _previous,
                        icon: const Icon(Icons.arrow_forward), // در RTL یعنی «قبلی»
                        label: const Text('مرحله قبل'),
                      ),
                    const Spacer(),
                    if (state.step < 3)
                      FilledButton.icon(
                        onPressed: state.busy ? null : _next,
                        icon: state.busy
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.arrow_back), // در RTL یعنی «بعدی»
                        label: Text(state.busy
                            ? 'در حال ذخیره…'
                            : state.step == 0
                                ? 'ثبت مشکل و ادامه'
                                : 'مرحله بعد'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.navyBlue,
                          minimumSize: const Size(150, 52),
                        ),
                      )
                    else
                      FilledButton.icon(
                        onPressed: state.verified && !state.busy
                            ? _closeProblem
                            : null,
                        icon: const Icon(Icons.lock_open),
                        label: const Text('بستن مسئله'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.success,
                          disabledBackgroundColor:
                              AppColors.success.withValues(alpha: .3),
                          minimumSize: const Size(150, 52),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
