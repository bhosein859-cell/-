import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../features/level1/level1_wizard_screen.dart';
import '../../features/level2/level2_wizard_screen.dart';
import '../../features/level3/level3_wizard_screen.dart';
import '../widgets/level_card.dart';

/// صفحه‌ی «مشکل جدید» — انتخاب سطح حل مسئله.
///
/// فاز ۱: ویزارد سطح ۱ (حل سریع) فعال است؛ سطح‌های ۲ و  در فازهای بعدی.
class NewProblemScreen extends StatelessWidget {
  const NewProblemScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ثبت مشکل جدید',
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  'سطح حل مسئله را انتخاب کنید؛ ویزارد متناسب با همان سطح اجرا می‌شود.',
                  style: theme.textTheme.bodyLarge
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 28),
                Wrap(
                  spacing: 20,
                  runSpacing: 20,
                  crossAxisAlignment: WrapCrossAlignment.start,
                  children: [
                    // ── سطح ۱: فعال (ویزارد ۴ مرحله‌ای) ──
                    LevelCard(
                      level: 1,
                      color: AppColors.level1,
                      title: 'حل سریع (Quick Fix)',
                      subtitle:
                          'برای مشکلات ساده و روزمره؛ حل در کمتر از ۱۵ دقیقه.',
                      bullets: [
                        'ثبت مشکل با عکس و اولویت',
                        'ریشه‌یابی سریع با ۵ چرا',
                        'ثبت اقدام فوری و بستن مسئله',
                        'خروجی گزارش Word',
                      ],
                      onSelect: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const Level1WizardScreen()),
                      ),
                    ),
                    // ── سطح ۲: فعال (ویزارد ۸ گامه تحلیلی) ──
                    LevelCard(
                      level: 2,
                      color: AppColors.level2,
                      title: 'متوسط و تیمی',
                      subtitle:
                          'برای مشکلات تکرارشونده؛ با تحلیل داده و همفکری تیم (۱ تا ۷ روز).',
                      bullets: [
                        'تعریف 5W2H + تیم + شاخص پایه',
                        'استخوان‌ماهی تعاملی و پارتو',
                        'درخت ۵ چرا + گانت چارت',
                        'خروجی Word چندصفحه‌ای و Excel',
                      ],
                      onSelect: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const Level2WizardScreen()),
                      ),
                    ),
                    LevelCard(
                      level: 3,
                      color: AppColors.level3,
                      title: 'گسترده و بحرانی',
                      subtitle:
                          'برای مشکلات استراتژیک؛ تحلیل عمیق، تیم چندتخصصی و ۱۲ گام.',
                      bullets: [
                        'انتخاب متدولوژی: 8D، DMAIC، A3، KT، RCA جامع',
                        'تحلیل آماری + FMEA + پایلوت + هزینه کیفیت',
                        'گزارش جامع Word، Excel پنج‌شیته و بایگانی PDF',
                      ],
                      onSelect: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const Level3WizardScreen()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: .08),
                    borderRadius: BorderRadius.circular(14),
                    border:
                        Border.all(color: AppColors.success.withValues(alpha: .35)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.verified_outlined,
                          color: AppColors.success),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'ویزاردهای سطح ۱ (حل سریع)، سطح ۲ (تیمی) و سطح ۳ '
                          '(گسترده و بحرانی) هر سه فعال هستند.',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
