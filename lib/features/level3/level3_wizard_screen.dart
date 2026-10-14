import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/persian_utils.dart';
import '../../data/models/level3_models.dart';
import 'level3_provider.dart';
import 'level3_state.dart';
import 'steps/step01_02.dart';
import 'steps/step03_statistics.dart';
import 'steps/step04_fmea.dart';
import 'steps/step05_06.dart';
import 'steps/step07_08.dart';
import 'steps/step09_10.dart';
import 'steps/step11_12.dart';

/// ویزارد ۱۲ گامه‌ی سطح ۳ — «گسترده و بحرانی».
///
/// - انتخاب متدولوژی در ورود (8D / DMAIC / A3 / KT / RCA جامع)
/// - برچسب هر گام مطابق متدولوژی انتخابی تغییر می‌کند
/// - گیت سخت: بدون تایید مدیر از گام مهار عبور نمی‌کند
/// - ذخیره‌ی خودکار + خروج با تاییدیه + نشان «ذخیره شد»
class Level3WizardScreen extends ConsumerStatefulWidget {
  const Level3WizardScreen({super.key});

  @override
  ConsumerState<Level3WizardScreen> createState() => _Level3WizardScreenState();
}

class _Level3WizardScreenState extends ConsumerState<Level3WizardScreen> {
  final PageController _page = PageController();

  @override
  void initState() {
    super.initState();
    ref.listenManual(level3WizardProvider, (prev, next) {
      if (prev?.step != next.step && _page.hasClients) {
        _page.animateToPage(next.step,
            duration: const Duration(milliseconds: 260), curve: Curves.easeOut);
      }
    });
  }

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  Future<bool> _confirmExit() async =>
      await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('خروج از ویزارد سطح ۳؟'),
          content: const Text('نگران نباشید؛ همه‌ی تغییرات به‌صورت خودکار ذخیره شده‌اند.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('ماندن')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('خروج')),
          ],
        ),
      ) ??
      false;

  /// 🚧 گیت سخت: قبل از تایید مدیر، هیچ عبوری از گام ۲ به بعد مجاز نیست.
  bool _blocked(Level3State state) {
    if (!state.containmentApproved) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        backgroundColor: AppColors.level3,
        content: Text(
            '⛔ گیت مهار: ابتدا باید مدیر اثربخشی اقدامات مهار را تایید کند.'),
      ));
      return true;
    }
    return false;
  }

  void _next(Level3State state) {
    final notifier = ref.read(level3WizardProvider.notifier);
    if (state.step == 2 && !state.containmentApproved && _blocked(state)) {
      return;
    }
    if (state.step < 12) notifier.setStep(state.step + 1);
  }

  void _go(int target) {
    final state = ref.read(level3WizardProvider);
    if (target >= 3 && !state.containmentApproved && _blocked(state)) return;
    ref.read(level3WizardProvider.notifier).setStep(target);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(level3WizardProvider);
    final notifier = ref.read(level3WizardProvider.notifier);
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
              Text('ویزارد سطح ۳ — گسترده و بحرانی${state.problemId != null ? ' • ${state.methodology.label}' : ''}',
                  style: const TextStyle(fontSize: 16)),
              Text(
                state.lastSavedAt == null
                    ? 'ذخیره‌ی خودکار فعال'
                    : '✓ ذخیره‌ی خودکار: ${PersianUtils.faDateTime(state.lastSavedAt!)}',
                style: const TextStyle(
                    fontSize: 11, color: AppColors.success, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          actions: [
            if (state.problemId != null)
              Padding(
                padding: const EdgeInsets.all(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.level3,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text('سطح ۳',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 12)),
                ),
              ),
          ],
        ),
        body: Column(
          children: [
            // ── نوار پیشرفت ۱۲ گامه با برچسب متدولوژی ──
            if (state.problemId != null)
              SizedBox(
                height: 64,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: 12,
                  separatorBuilder: (_, __) => const SizedBox(width: 5),
                  itemBuilder: (context, i) {
                    final idx = i + 1; // گام‌ها از ۱ شماره‌گذاری می‌شوند
                    final active = idx == state.step;
                    final done = idx < state.step;
                    return GestureDetector(
                      onTap: () => _go(idx),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 7),
                        decoration: BoxDecoration(
                          color: active ? AppColors.navyBlue : theme.colorScheme.surface,
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
                              radius: 10,
                              backgroundColor: active
                                  ? AppColors.orange
                                  : theme.colorScheme.primary.withValues(alpha: .12),
                              child: Text(
                                PersianUtils.faDigits('$idx'),
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    color: active
                                        ? Colors.white
                                        : theme.colorScheme.primary),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              state.methodology.stepTag(idx),
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: active ? FontWeight.w800 : FontWeight.w500,
                                color: active ? Colors.white : null,
                              ),
                            ),
                            if (done && !active) ...[
                              const SizedBox(width: 4),
                              const Icon(Icons.check, size: 12, color: AppColors.success),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            const Divider(height: 1),

            // ── بدنه: ۱۳ صفحه (شروع + ۱۲ گام) ──
            Expanded(
              child: PageView(
                controller: _page,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  const _StartCard(),
                  const _Body(child: Step1Screen()),
                  const _Body(child: Step2Screen()),
                  const _Body(child: Step3Screen()),
                  const _Body(child: Step4Screen()),
                  const _Body(child: Step5Screen()),
                  const _Body(child: Step6Screen()),
                  const _Body(child: Step7Screen()),
                  const _Body(child: Step8Screen()),
                  const _Body(child: Step9Screen()),
                  const _Body(child: Step10Screen()),
                  const _Body(child: Step11Screen()),
                  const _Body(child: Step12Screen()),
                ],
              ),
            ),

            // ── دکمه‌های ناوبری ──
            if (state.problemId != null)
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
                  child: Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: state.step > 1
                            ? () => notifier.setStep(state.step - 1)
                            : null,
                        icon: const Icon(Icons.arrow_forward),
                        label: const Text('قبلی'),
                      ),
                      const Spacer(),
                      Text(
                        '${PersianUtils.faDigits('${state.step}')} از ۱۲',
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 13),
                      ),
                      const Spacer(),
                      if (state.step < 12)
                        FilledButton.icon(
                          onPressed: () => _next(state),
                          icon: const Icon(Icons.arrow_back),
                          iconAlignment: IconAlignment.end,
                          label: const Text('بعدی'),
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

/// قاب اسکرول‌شونده‌ی بدنه‌ی هر گام
class _Body extends StatelessWidget {
  const _Body({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 980),
              child: child,
            ),
          ),
        ),
      );
}

/// صفحه‌ی شروع: عنوان پروژه + انتخاب متدولوژی
class _StartCard extends ConsumerStatefulWidget {
  const _StartCard();

  @override
  ConsumerState<_StartCard> createState() => _StartCardState();
}

class _StartCardState extends ConsumerState<_StartCard> {
  final _title = TextEditingController();
  Methodology _methodology = Methodology.d8;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(level3WizardProvider.notifier);
    final theme = Theme.of(context);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(
            children: [
              const Icon(Icons.workspace_premium,
                  size: 56, color: AppColors.level3),
              const SizedBox(height: 10),
              Text('سطح ۳ — گسترده و بحرانی',
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w900, color: AppColors.navyBlue)),
              const SizedBox(height: 6),
              const Text(
                'شکایات کلیدی مشتریان، حوادث ایمنی، توقف‌های پرهزینه و '
                'بهبودهای استراتژیک — با تیم چندتخصصی و تحلیل آماری عمیق.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _title,
                decoration: const InputDecoration(
                  labelText: 'عنوان پروژه',
                  hintText: 'مثلاً: کاهش ضایعات خط رنگ و بازپرداخت مشتری',
                  prefixIcon: Icon(Icons.title),
                ),
              ),
              const SizedBox(height: 18),
              Align(
                alignment: Alignment.centerRight,
                child: Text('انتخاب متدولوژی:',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w800)),
              ),
              const SizedBox(height: 8),
              ...Methodology.values.map(
                (m) => Card(
                  color: _methodology == m
                      ? AppColors.navyBlue.withValues(alpha: .07)
                      : null,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: _methodology == m
                          ? AppColors.navyBlue
                          : theme.dividerColor.withValues(alpha: .7),
                      width: _methodology == m ? 2 : 1,
                    ),
                  ),
                  child: ListTile(
                    onTap: () => setState(() => _methodology = m),
                    leading: Icon(
                      _methodology == m
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      color: _methodology == m
                          ? AppColors.navyBlue
                          : Colors.black38,
                    ),
                    title: Text(m.label,
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                    subtitle: Text(m.desc, style: const TextStyle(fontSize: 12)),
                    trailing: Wrap(
                      spacing: 4,
                      children: [
                        for (var i = 1; i <= 3; i++)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.orange.withValues(alpha: .12),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(m.stepTag(i),
                                style: const TextStyle(
                                    fontSize: 10, color: AppColors.orange,
                                    fontWeight: FontWeight.w700)),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    backgroundColor: AppColors.navyBlue,
                  ),
                  icon: const Icon(Icons.rocket_launch),
                  onPressed: () async {
                    final err = await notifier.createProblem(
                        _title.text, _methodology);
                    if (err != null && context.mounted) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(content: Text(err)));
                    } else if (err == null && context.mounted) {
                      notifier.setStep(1);
                    }
                  },
                  label: const Text('شروع پروژه',
                      style:
                          TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
