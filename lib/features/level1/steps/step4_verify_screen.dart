import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../level1_provider.dart';

/// مرحله ۴: بستن و تایید — چک‌باکس ساده «آیا مشکل برطرف شد؟»
///
/// بله (تیک) → فعال‌شدن دکمه‌ی «بستن مسئله»
/// خیر (برداشتن تیک) → بازگشت خودکار به مرحله‌ی ۲ با پیام راهنما
class Step4VerifyScreen extends ConsumerWidget {
  const Step4VerifyScreen({super.key});

  void _onVerifyChanged(WidgetRef ref, bool? value) {
    final notifier = ref.read(level1WizardProvider.notifier);
    if (value == true) {
      notifier.update((s) => s.copyWith(verified: true));
    } else {
      // بازگشت خودکار به مرحله‌ی ۲ (۵ چرا) با پیام راهنما
      notifier.onAnswerNo();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              Text('بستن و تایید',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text(
                'مرور خلاصه‌ی کار:',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 16),

              // خلاصه برای مرور سریع
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: theme.dividerColor.withValues(alpha: .6)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      state.title,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    if (state.whys.first.trim().isNotEmpty)
                      _Line(
                          'ریشه‌یابی: ${state.whys.where((w) => w.trim().isNotEmpty).length} چرا پاسخ داده شد'),
                    if (state.actionTitle.trim().isNotEmpty)
                      _Line('اقدام: ${state.actionTitle}'),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // ── چک‌باکس ساده‌ی تایید ──
              InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => _onVerifyChanged(ref, !state.verified),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    color: state.verified
                        ? AppColors.success.withValues(alpha: .1)
                        : theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: state.verified
                          ? AppColors.success
                          : theme.dividerColor.withValues(alpha: .6),
                      width: state.verified ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 32,
                        height: 32,
                        child: Checkbox(
                          value: state.verified,
                          activeColor: AppColors.success,
                          onChanged: (v) => _onVerifyChanged(ref, v),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'آیا مشکل برطرف شد؟',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: state.verified
                                ? AppColors.success
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              if (state.verified)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.success.withValues(alpha: .5)),
                  ),
                  child: const Text(
                    'عالی! با زدن دکمه‌ی «بستن مسئله» در پایین، مسئله بسته شده '
                    'و در لیست پروژه‌ها با نشان سبز «انجام شده» ثبت می‌شود.',
                    style: TextStyle(
                        fontWeight: FontWeight.w700, color: AppColors.success),
                  ),
                ),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ],
    );
  }
}

class _Line extends StatelessWidget {
  const _Line(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          const Icon(Icons.check, size: 16, color: AppColors.success),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: theme.textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}
