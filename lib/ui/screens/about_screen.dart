import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/persian_utils.dart';

/// صفحه‌ی «درباره ما» — هویت محصول، سازنده و نقشه‌ی راه.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const List<String> _standardFeatures = [
    'PDCA', '8D', 'DMAIC', '۵ چرا', 'استخوان‌ماهی',
    'FMEA', 'پارتو', 'خروجی Word', 'خروجی Excel',
  ];

  static const List<String> _innovativeFeatures = [
    'هوش مصنوعی آفلاین', 'DNA مسئله', 'ماشین زمان',
    'شبیه‌ساز تأثیر', 'تبدیل گفتار به متن',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: theme.dividerColor.withValues(alpha: .6)),
                  ),
                  child: Center(
                    child: SvgPicture.asset('assets/images/logo.svg',
                        width: 82, height: 82),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  AppConstants.appName,
                  style: theme.textTheme.headlineMedium
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                FutureBuilder<PackageInfo>(
                  future: PackageInfo.fromPlatform(),
                  builder: (context, snapshot) {
                    final build = snapshot.data == null
                        ? AppConstants.appVersion
                        : 'نسخه‌ی ${snapshot.data!.version}'
                            ' (ساخت ${snapshot.data!.buildNumber})';
                    return Text(
                      '${AppConstants.appNameEn} • $build',
                      style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant),
                    );
                  },
                ),
                const SizedBox(height: 6),
                Text(
                  AppConstants.phaseName,
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.orange, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 20),

                // توضیح محصول
                Text(
                  '«${AppConstants.appName}» یک دستیار حل مسئله‌ی سه‌سطحی است '
                  'که کاملاً آفلاین کار می‌کند: بدون اینترنت، بدون سرور ابری و '
                  'با دیتابیس محلی. از مشکلات ساده‌ی روزمره تا بحران‌های استراتژیک، '
                  'گره‌گشا شما را قدم‌به‌قدم از «گره» به «راه‌حل» می‌رساند.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(height: 1.9).merge(theme.textTheme.bodyMedium),
                ),
                const SizedBox(height: 24),

                // کارت سازنده
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.navyBlue, AppColors.navyBlueLight],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.emoji_events, color: AppColors.orange),
                      SizedBox(width: 10),
                      Column(
                        children: [
                          Text(
                            'سازنده و مالک',
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                          Text(
                            AppConstants.creator,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // نقشه راه ۶۶ ویژگی
                _RoadmapCard(
                  title: 'نقشه‌ی راه: '
                      '${PersianUtils.faDigits('${AppConstants.roadmapTotalFeatures}')} ویژگی',
                  subtitle: 'نمونه‌ای از قابلیت‌های نسخه‌ی نهایی',
                  sections: const [
                    ('۳۳ ویژگی استاندارد جهانی', _standardFeatures, AppColors.navyBlue),
                    ('۳۳ ویژگی نوآورانه', _innovativeFeatures, AppColors.orange),
                  ],
                ),
                const SizedBox(height: 16),

                // آفلاین بودن
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                        color: AppColors.success.withValues(alpha: .4)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.wifi_off, size: 18, color: AppColors.success),
                      SizedBox(width: 8),
                      Text(
                        '۱۰۰٪ آفلاین — بدون اینترنت، بدون سرور ابری',
                        style: TextStyle(
                          color: AppColors.success,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// کارت نقشه‌ی راه ۶۶ ویژگی.
class _RoadmapCard extends StatelessWidget {
  const _RoadmapCard({
    required this.title,
    required this.subtitle,
    required this.sections,
  });

  final String title;
  final String subtitle;
  final List<(String, List<String>, Color)> sections;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withValues(alpha: .6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(subtitle,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 14),
          for (final (heading, chips, color) in sections) ...[
            Text(heading,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: color, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final chip in chips)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: .1),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: color.withValues(alpha: .4)),
                    ),
                    child: Text(
                      chip,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}
