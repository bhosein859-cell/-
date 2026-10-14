import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/persian_utils.dart';
import '../../data/models/problem.dart';
import '../../data/repositories/problem_repository.dart';
import '../../features/level1/level1_provider.dart';
import '../../services/word_exporter.dart';
import '../widgets/empty_state.dart';
import '../widgets/problem_status_badge.dart';

/// صفحه‌ی «پروژه‌های فعال» — لیست واقعی مسائل از دیتابیس.
///
/// یکپارچگی با ویزارد: با ثبت/بستن هر مسئله، [problemsVersionProvider]
/// تغییر کرده و این لیست به‌صورت خودکار تازه می‌شود.
class ActiveProjectsScreen extends ConsumerStatefulWidget {
  const ActiveProjectsScreen({super.key});

  @override
  ConsumerState<ActiveProjectsScreen> createState() =>
      _ActiveProjectsScreenState();
}

class _ActiveProjectsScreenState extends ConsumerState<ActiveProjectsScreen> {
  Future<List<Problem>>? _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    setState(() {
      _future = ref.read(problemRepositoryProvider).getAllProblems();
    });
  }

  Future<void> _exportWord(Problem problem) async {
    try {
      final repo = ref.read(problemRepositoryProvider);
      final fresh = await repo.getProblem(problem.id!);
      if (fresh == null) return;
      final actions = await repo.actionsForProblem(problem.id!);
      final path = await WordExporter()
          .exportLevel1Report(problem: fresh, actions: actions);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('گزارش Word ذخیره شد:\n$path')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا در ساخت گزارش Word: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // با تغییر نسخه، بازسازی خودگار (پس از ثبت/بستن مسئله در ویزارد)
    ref.watch(problemsVersionProvider);
    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: () async => _load(),
      child: FutureBuilder<List<Problem>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final problems = snapshot.data ?? const <Problem>[];
          if (problems.isEmpty) {
            return const EmptyState(
              icon: Icons.folder_open_outlined,
              title: 'هنوز مسئله‌ای ثبت نشده است',
              subtitle:
                  'از بخش «مشکل جدید»، ویزارد حل سریع (سطح ۱) را آغاز کنید;\nمسائل ثبت‌شده اینجا با وضعیتشان نمایش داده می‌شوند.',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: problems.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final problem = problems[index];
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: theme.dividerColor.withValues(alpha: .6)),
                ),
                child: Row(
                  children: [
                    // نشان سطح
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.level1.withValues(alpha: .12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          PersianUtils.faDigits('${problem.level}'),
                          style: const TextStyle(
                            color: AppColors.level1,
                            fontWeight: FontWeight.w900,
                            fontSize: 17,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            problem.title,
                            style: theme.textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            [
                              problem.levelFa,
                              if ((problem.metadata['location']?.toString()
                                          .isEmpty ??
                                      true) ==
                                  false)
                                problem.metadata['location'].toString(),
                              if (problem.createdAt != null)
                                PersianUtils.faDate(problem.createdAt!),
                            ].join(' • '),
                            style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    // دکمه‌ی خروجی Word
                    IconButton(
                      tooltip: 'خروجی گزارش Word',
                      icon: const Icon(Icons.description_outlined),
                      color: AppColors.navyBlue,
                      onPressed: () => _exportWord(problem),
                    ),
                    const SizedBox(width: 4),
                    ProblemStatusBadge(status: problem.status),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
