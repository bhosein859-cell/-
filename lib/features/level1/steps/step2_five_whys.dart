import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/persian_utils.dart';
import '../level1_provider.dart';

/// مرحله ۲: ریشه‌یابی سریع با «۵ چرا».
///
/// رفتار تعاملی: با پر شدن هر «چرا»، فیلد بعدی به‌صورت خودکار فعال شده
/// و فوکوس می‌گیرد تا کاربر تا رسیدن به ریشه‌ی اصلی هدایت شود.
class Step2FiveWhys extends ConsumerStatefulWidget {
  const Step2FiveWhys({super.key});

  @override
  ConsumerState<Step2FiveWhys> createState() => _Step2FiveWhysState();
}

class _Step2FiveWhysState extends ConsumerState<Step2FiveWhys> {
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    final whys = ref.read(level1WizardProvider).whys;
    _controllers = List.generate(
        5, (i) => TextEditingController(text: whys[i]));
    _focusNodes = List.generate(5, (_) => FocusNode());
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _onWhyChanged(int index, String value) {
    final notifier = ref.read(level1WizardProvider.notifier);
    final wasEmpty =
        ref.read(level1WizardProvider).whys[index].trim().isEmpty;

    notifier.update((s) {
      final whys = List<String>.of(s.whys);
      whys[index] = value;
      return s.copyWith(whys: whys);
    });

    // فعال‌سازی و فوکوس خودکار فیلد بعدی وقتی اولین پاسخ تازه تایپ شد
    if (wasEmpty && value.trim().isNotEmpty && index < 4) {
      _focusNodes[index + 1].requestFocus();
    }
  }

  bool _isEnabled(List<String> whys, int index) =>
      index == 0 || whys[index - 1].trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(level1WizardProvider);
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // پیام راهنما هنگام بازگشت خودکار از مرحله‌ی ۴
              if (state.retryNotice != null)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 18),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.orange.withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.orange.withValues(alpha: .5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          color: AppColors.orange),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          state.retryNotice!,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.orange),
                        ),
                      ),
                    ],
                  ),
                ),

              Text('چرا این مشکل پیش آمد؟',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text(
                'هر پاسخ را بنویسید؛ ما شما را قدم‌به‌قدم تا ریشه‌ی اصلی هدایت می‌کنیم.',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 22),

              for (var i = 0; i < 5; i++) ...[
                Opacity(
                  opacity: _isEnabled(state.whys, i) ? 1 : .38,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: _isEnabled(state.whys, i)
                            ? AppColors.navyBlue
                            : theme.colorScheme.onSurfaceVariant,
                        child: Text(
                          PersianUtils.faDigits('${i + 1}'),
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _controllers[i],
                          focusNode: _focusNodes[i],
                          enabled: _isEnabled(state.whys, i),
                          onChanged: (v) => _onWhyChanged(i, v),
                          decoration: InputDecoration(
                            labelText:
                                'چرا؟ ${PersianUtils.faDigits('${i + 1}')}',
                            hintText: i == 0
                                ? 'مثلاً: چون واشر فرسوده بود'
                                : 'و چرا مرحله‌ی قبل؟',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              const SizedBox(height: 8),
              Text(
                '💡 راهنما: رسیدن به «چرا»ی سوم به بعد، معمولاً ریشه‌ی اصلی را آشکار می‌کند.',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ],
    );
  }
}
