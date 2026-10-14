import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/persian_utils.dart';
import '../../data/database/database_helper.dart';
import '../../data/models/problem.dart';
import '../../data/repositories/problem_repository.dart';
import '../../features/level1/level1_provider.dart';
import '../widgets/problem_status_badge.dart';

/// داشبورد اصلی — آمار زنده + آخرین مسائل + بنر نقشه راه.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // تازه‌سازی خودکار پس از ثبت/بستن مسئله در ویزارد
    ref.watch(problemsVersionProvider);
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'سلام! 👋',
          style:
              theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          'به «${AppConstants.appName}» خوش آمدید؛ هر گره، یک فرصت برای یادگیری است.',
          style: theme.textTheme.bodyLarge
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 24),

        // ── کارت‌های آماری زنده ──
        FutureBuilder<DashboardStats>(
          future: DatabaseHelper.instance.dashboardStats(),
          builder: (context, snapshot) {
            final stats = snapshot.data ??
                const DashboardStats(
                    openProblems: 0, pendingActions: 0, knowledgeArticles: 0);
            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _StatCard(
                  icon: Icons.assignment_outlined,
                  color: AppColors.navyBlue,
                  label: 'مسائل باز',
                  value: stats.openProblems,
                ),
                _StatCard(
                  icon: Icons.pending_actions_outlined,
                  color: AppColors.orange,
                  label: 'اقدامات در جریان',
                  value: stats.pendingActions,
                ),
                _StatCard(
                  icon: Icons.auto_stories_outlined,
                  color: AppColors.success,
                  label: 'مقالات بانک دانش',
                  value: stats.knowledgeArticles,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 24),

        // ── آخرین مسائل (یکپارچگی با ویزارد سطح ۱) ──
        Row(
          children: [
            Icon(Icons.recent_actors_outlined,
                size: 20, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              'آخرین مسائل',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
          ],
        ),
        const SizedBox(height: 12),
        FutureBuilder<List<Problem>>(
          future: ref
              .read(problemRepositoryProvider)
              .getAllProblems(limit: 4),
          builder: (context, snapshot) {
            final problems = snapshot.data ?? const <Problem>[];
            if (problems.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: theme.dividerColor.withValues(alpha: .6)),
                ),
                child: Text(
                  'هنوز مسئله‌ای ثبت نشده است. از «مشکل جدید» ویزارد حل سریع را شروع کنید.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant),
                ),
              );
            }
            return Column(
              children: [
                for (final problem in problems) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: theme.dividerColor.withValues(alpha: .6)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            problem.title,
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ProblemStatusBadge(status: problem.status),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ],
            );
          },
        ),
        const SizedBox(height: 8),

        // ── بنر نقشه راه ──
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              colors: [AppColors.navyBlue, AppColors.navyBlueLight],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.rocket_launch, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    AppConstants.phaseName,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'نسخه‌ی نهایی «${AppConstants.appName}» با '
                '${PersianUtils.faDigits('${AppConstants.roadmapTotalFeatures}')}'
                ' ویژگی عرضه می‌شود: ۳۳ قابلیت استاندارد جهانی'
                ' (PDCA، 8D، DMAIC، ۵ چرا، استخوان‌ماهی، FMEA، پارتو، خروجی Word و Excel و...)'
                ' و ۳۳ قابلیت نوآورانه'
                ' (هوش مصنوعی آفلاین، DNA مسئله، ماشین زمان، شبیه‌ساز تأثیر، تبدیل گفتار به متن و...).',
                style:
                    const TextStyle(color: Colors.white, fontSize: 13.5, height: 1.9),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.badge_outlined,
                      size: 18, color: AppColors.orange),
                  const SizedBox(width: 6),
                  Text(
                    'ساخته شده توسط ${AppConstants.creator}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// کارت آمار کوچک در داشبورد.
class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color color;
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 210,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withValues(alpha: .6)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                PersianUtils.faDigits('$value'),
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              Text(
                label,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
