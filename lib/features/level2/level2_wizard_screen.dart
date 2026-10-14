import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/persian_utils.dart';
import '../../data/models/attachment.dart';
import '../../data/models/audit_entry.dart';
import '../../data/repositories/level2_repository.dart';
import '../../data/repositories/problem_repository.dart';
import 'level2_provider.dart';
import 'steps/step1_definition.dart';
import 'steps/step2_causes.dart';
import 'steps/step3_whys_tree.dart';
import 'steps/step4_planning.dart';
import 'steps/step5_execution.dart';
import 'steps/step6_check.dart';
import 'steps/step7_standardization.dart';
import 'steps/step8_report.dart';

/// ویزارد ۸ گامه‌ی سطح ۲ (متوسط و تیمی).
///
/// - نوار پیشرفت افقی ۸ گام در بالا با جابه‌جایی آزاد
/// - پنل کناری در دسکتاپ (تیم / تاریخچه / پیوست‌ها)
/// - نشانگر «ذخیره خودکار» + دکمه‌ی خروج با تاییدیه
class Level2WizardScreen extends ConsumerStatefulWidget {
  const Level2WizardScreen({super.key});

  @override
  ConsumerState<Level2WizardScreen> createState() => _Level2WizardScreenState();
}

class _Level2WizardScreenState extends ConsumerState<Level2WizardScreen> {
  final PageController _page = PageController();
  final TextEditingController _title = TextEditingController();

  static const List<String> _labels = [
    'تعریف مسئله',
    'تحلیل علل',
    'ریشه‌یابی',
    'برنامه‌ریزی',
    'اجرا',
    'بررسی',
    'استانداردسازی',
    'گزارش نهایی',
  ];

  @override
  void initState() {
    super.initState();
    ref.listenManual(level2WizardProvider, (prev, next) {
      if (prev?.step != next.step && _page.hasClients) {
        _page.animateToPage(next.step,
            duration: const Duration(milliseconds: 260), curve: Curves.easeOut);
      }
    });
  }

  @override
  void dispose() {
    _page.dispose();
    _title.dispose();
    super.dispose();
  }

  Future<bool> _confirmExit() async =>
      await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('خروج از ویزارد سطح ۲؟'),
          content: const Text('نگران نباشید؛ همه‌ی تغییرات به‌صورت خودکار ذخیره شده‌اند.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('ماندن')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('خروج')),
          ],
        ),
      ) ??
      false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(level2WizardProvider);
    final notifier = ref.read(level2WizardProvider.notifier);
    final theme = Theme.of(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop && await _confirmExit()) {
          if (mounted) Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
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
              const Text('ویزارد سطح ۲ — متوسط و تیمی', style: TextStyle(fontSize: 16)),
              Text(
                state.lastSavedAt == null
                    ? 'ذخیره‌ی خودکار فعال'
                    : '✓ ذخیره‌ی خودکار: ${PersianUtils.faDateTime(state.lastSavedAt!)}',
                style: TextStyle(
                    fontSize: 11, color: AppColors.success, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          actions: const [
            Padding(
              padding: EdgeInsets.all(10),
              child: _LevelChip(),
            ),
          ],
        ),
        body: Column(
          children: [
            // ── نوار پیشرفت افقی ۸ گام ──
            SizedBox(
              height: 62,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: 8,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (context, i) {
                  final active = i == state.step;
                  final done = i < state.step || state.problemId != null;
                  return GestureDetector(
                    onTap: state.problemId == null
                        ? null
                        : () => notifier.setStep(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: active
                            ? AppColors.navyBlue
                            : theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                            color: active
                                ? AppColors.navyBlue
                                : theme.dividerColor.withValues(alpha: .7)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            radius: 11,
                            backgroundColor: active
                                ? AppColors.orange
                                : theme.colorScheme.primary.withValues(alpha: .12),
                            child: Text(
                              PersianUtils.faDigits('${i + 1}'),
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  color: active ? Colors.white : theme.colorScheme.primary),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _labels[i],
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: active ? FontWeight.w800 : FontWeight.w500,
                              color: active ? Colors.white : null,
                            ),
                          ),
                          if (done && !active) ...[
                            const SizedBox(width: 6),
                            const Icon(Icons.check, size: 13, color: AppColors.success),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const Divider(height: 1),

            // ── بدنه ──
            Expanded(
              child: state.problemId == null
                  ? _StartCard(titleController: _title)
                  : LayoutBuilder(
                      builder: (context, c) {
                        final content = PageView(
                          controller: _page,
                          physics: const NeverScrollableScrollPhysics(),
                          children: const [
                            Step1Definition(),
                            Step2Causes(),
                            Step3WhysTree(),
                            Step4Planning(),
                            Step5Execution(),
                            Step6Check(),
                            Step7Standardization(),
                            Step8Report(),
                          ],
                        );
                        // پنل کناری فقط در دسکتاپ عریض
                        if (c.maxWidth >= 1200) {
                          return Row(
                            children: [
                              Expanded(child: content),
                              const VerticalDivider(width: 1),
                              const _SidePanel(),
                            ],
                          );
                        }
                        return content;
                      },
                    ),
            ),

            // ── ناوبری پایین ──
            if (state.problemId != null)
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: Row(
                    children: [
                      if (state.step > 0)
                        OutlinedButton.icon(
                          onPressed: () => notifier.setStep(state.step - 1),
                          icon: const Icon(Icons.arrow_forward),
                          label: const Text('گام قبل'),
                        ),
                      const Spacer(),
                      if (state.step < 7)
                        FilledButton.icon(
                          onPressed: () => notifier.setStep(state.step + 1),
                          icon: const Icon(Icons.arrow_back),
                          label: const Text('گام بعد'),
                          style: FilledButton.styleFrom(
                              backgroundColor: AppColors.navyBlue,
                              minimumSize: const Size(140, 50)),
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

class _LevelChip extends StatelessWidget {
  const _LevelChip();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.level2.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(999),
        ),
        child: const Text('سطح ۲',
            style: TextStyle(
                color: AppColors.level2, fontWeight: FontWeight.w800, fontSize: 12)),
      );
}

/// کارت شروع: ساخت مسئله‌ی سطح ۲ با عنوان
class _StartCard extends ConsumerWidget {
  const _StartCard({required this.titleController});

  final TextEditingController titleController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final busy = ref.watch(level2WizardProvider).busy;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('شروع مسئله‌ی سطح ۲',
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Text('عنوان مسئله‌ی تکرارشونده/تیمی را بنویسید؛ شش شاخه‌ی استخوان‌ماهی '
                  'به‌صورت خودکار ساخته می‌شوند.',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              const SizedBox(height: 18),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                    hintText: 'مثلاً: تکرار عیب جوش در خط تولید ۲'),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: busy
                      ? null
                      : () async {
                          final err = await ref
                              .read(level2WizardProvider.notifier)
                              .createProblem(titleController.text);
                          if (err != null && context.mounted) {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(SnackBar(content: Text(err)));
                          }
                        },
                  icon: busy
                      ? const SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.play_arrow_rounded),
                  label: const Text('شروع ویزارد ۸ گامه'),
                  style: FilledButton.styleFrom(
                      backgroundColor: AppColors.navyBlue,
                      minimumSize: const Size(0, 52)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// پنل کناری دسکتاپ: تیم / تاریخچه / پیوست‌ها
class _SidePanel extends ConsumerWidget {
  const _SidePanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(level2WizardProvider);
    final theme = Theme.of(context);

    return SizedBox(
      width: 300,
      child: DefaultTabController(
        length: 3,
        child: Column(
          children: [
            const TabBar(
              labelColor: AppColors.navyBlue,
              tabs: [
                Tab(text: 'تیم'),
                Tab(text: 'تاریخچه'),
                Tab(text: 'پیوست‌ها'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  // تیم
                  ListView(
                    padding: const EdgeInsets.all(14),
                    children: [
                      if (state.team.isEmpty) const Text('تیمی ثبت نشده است.'),
                      for (final m in state.team)
                        ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: const CircleAvatar(
                              backgroundColor: AppColors.navyBlue,
                              radius: 16,
                              child: Icon(Icons.person, size: 16, color: Colors.white)),
                          title: Text(m.name, style: const TextStyle(fontSize: 13)),
                          subtitle: Text(m.role, style: const TextStyle(fontSize: 11)),
                        ),
                    ],
                  ),
                  // تاریخچه
                  FutureBuilder<List<AuditEntry>>(
                    future: ref
                        .read(level2RepositoryProvider)
                        .history(state.problemId!),
                    builder: (context, snap) {
                      final items = snap.data ?? const <AuditEntry>[];
                      return ListView(
                        padding: const EdgeInsets.all(14),
                        children: [
                          for (final h in items)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.history, size: 15,
                                      color: AppColors.orange),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(h.action,
                                            style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700)),
                                        if (h.createdAt != null)
                                          Text(PersianUtils.faDateTime(h.createdAt!),
                                              style: TextStyle(
                                                  fontSize: 10,
                                                  color: theme.colorScheme.onSurfaceVariant)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (items.isEmpty) const Text('رویدادی ثبت نشده است.'),
                        ],
                      );
                    },
                  ),
                  // پیوست‌ها
                  FutureBuilder<List<Attachment>>(
                    future: ref
                        .read(problemRepositoryProvider)
                        .attachmentsForProblem(state.problemId!),
                    builder: (context, snap) {
                      final items = snap.data ?? const <Attachment>[];
                      return ListView(
                        padding: const EdgeInsets.all(14),
                        children: [
                          for (final a in items)
                            ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.attach_file,
                                  color: AppColors.orange, size: 18),
                              title: Text(a.fileName,
                                  style: const TextStyle(fontSize: 12)),
                            ),
                          if (items.isEmpty) const Text('پیوستی وجود ندارد.'),
                        ],
                      );
                    },
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
