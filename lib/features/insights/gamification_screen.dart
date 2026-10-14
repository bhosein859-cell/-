import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/gamification/gamification_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/persian_utils.dart';

/// ═══════════════════════════════════════════════════════════════
/// گیمیفیکیشن — نشان‌های کسب‌شده، امتیازها و جدول رتبه‌بندی تیم
/// ═══════════════════════════════════════════════════════════════
class GamificationScreen extends ConsumerStatefulWidget {
  const GamificationScreen({super.key});

  @override
  ConsumerState<GamificationScreen> createState() => _GamificationScreenState();
}

class _GamificationScreenState extends ConsumerState<GamificationScreen> {
  List<UserScore> _board = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final board = await ref.read(gamificationProvider).leaderboard();
    setState(() {
      _board = board;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('🏅 گیمیفیکیشن و افتخارات')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text('جدول رتبه‌بندی',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  if (_board.isEmpty) const Text('هنوز کاربری ثبت نشده است.'),
                  for (var i = 0; i < _board.length; i++)
                    Card(
                      color: i == 0
                          ? AppColors.orange.withValues(alpha: .1)
                          : null,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: i < 3
                              ? [AppColors.orange, Colors.grey,
                                  Colors.brown][i]
                              : AppColors.navyBlue.withValues(alpha: .12),
                          child: Text(
                            i < 3
                                ? ['🥇', '🥈', '🥉'][i]
                                : PersianUtils.faDigits('${i + 1}'),
                            style: TextStyle(
                                fontSize: i < 3 ? 16 : 13,
                                color: i < 3 ? null : AppColors.navyBlue),
                          ),
                        ),
                        title: Text(_board[i].displayName,
                            style: TextStyle(
                                fontWeight: i == 0 ? FontWeight.w900 : null)),
                        subtitle: Text(
                            '${PersianUtils.faDigits('${_board[i].closedCount}')} مسئله بسته‌شده'),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('${PersianUtils.faDigits('${_board[i].points}')}'
                                ' امتیاز',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.navyBlue)),
                            Text(
                              _board[i].earnedBadges.values.join(' '),
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const Divider(height: 28),
                  Text('نشان‌ها',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 3,
                    children: [
                      for (final e in GamificationService.badges.entries)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.navyBlue.withValues(alpha: .04),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Text(e.value.icon, style: const TextStyle(fontSize: 20)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(e.value.name,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 12.5)),
                                    Text(e.value.desc,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            fontSize: 10.5,
                                            color: Colors.black54)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}
