import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../data/database/database_helper.dart';
import 'archive_screen.dart';
import 'calendar_view_screen.dart';
import 'command_center_screen.dart';
import 'copq_dashboard_screen.dart';
import 'custom_wizard_screen.dart';
import 'gamification_screen.dart';
import 'global_search_screen.dart';
import 'impact_simulator_screen.dart';
import 'problem_dna_screen.dart';
import 'templates_screen.dart';
import 'time_machine_screen.dart';

/// ═══════════════════════════════════════════════════════════════
/// هاب «ابزارهای هوشمند» — دروازه‌ی ورود به تمام قابلیت‌های فاز ۴
/// ═══════════════════════════════════════════════════════════════
class FeaturesHubScreen extends StatelessWidget {
  const FeaturesHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const tools = <(IconData, Color, String, String, String)>[
      (Icons.hub, AppColors.navyBlue, 'dna', 'دی‌ان‌ای مسئله',
          'نقشه ارتباط مسائل سازمان با هم'),
      (Icons.history_edu, AppColors.level2, 'time', 'ماشین زمان',
          'پخش مجدد مراحل حل یک پروژه'),
      (Icons.calculate, AppColors.level3, 'impact', 'شبیه‌ساز تأثیر',
          'هزینه حل نشدن مسئله چقدر است؟'),
      (Icons.pie_chart, AppColors.orange, 'copq', 'داشبورد هزینه کیفیت',
          'محاسبه‌ی زنده‌ی COPQ در کل سازمان'),
      (Icons.emoji_events, AppColors.level2, 'game', 'گیمیفیکیشن',
          'نشان‌ها، امتیازها و جدول رتبه‌بندی'),
      (Icons.dashboard_customize, AppColors.navyBlue, 'command', 'اتاق فرمان',
          'نمای کلان پروژه‌ها + یادآورهای هوشمند'),
      (Icons.calendar_month, AppColors.success, 'calendar', 'تقویم مهلت‌ها',
          'اقدامات سررسیدشده روی تقویم'),
      (Icons.search, AppColors.navyBlue, 'search', 'جستجوی فراگیر',
          'جستجو در همه‌ی پروژه‌ها و دانش'),
      (Icons.account_tree, AppColors.orange, 'wizard', 'ویزاردهای سفارشی',
          'ویزارد اختصاصی صنعت خود را بسازید'),
      (Icons.copy_all, AppColors.level2, 'templates', 'قالب‌ها',
          'شروع مسئله جدید از الگوهای آماده'),
      (Icons.archive, AppColors.navyBlue, 'archive', 'بایگانی',
          'پروژه‌های بسته‌شده، بدون حذف'),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('✨ ابزارهای هوشمند')),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 260,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 2.6,
        ),
        itemCount: tools.length,
        itemBuilder: (context, i) {
          final t = tools[i];
          return _ToolCard(
            icon: t.$1,
            color: t.$2,
            title: t.$4,
            desc: t.$5,
            onTap: () => _open(context, t.$3),
          );
        },
      ),
    );
  }

  void _open(BuildContext context, String key) {
    final db = ProviderScope.containerOf(context).read(databaseProvider);
    switch (key) {
      case 'time':
        _pickProblemThen(context, db);
      case 'impact':
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const ImpactSimulatorScreen()));
      case 'copq':
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const CopqDashboardScreen()));
      case 'game':
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const GamificationScreen()));
      case 'command':
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const CommandCenterScreen()));
      case 'calendar':
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const CalendarViewScreen()));
      case 'search':
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const GlobalSearchScreen()));
      case 'wizard':
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const CustomWizardScreen()));
      case 'templates':
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const TemplatesScreen()));
      case 'archive':
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const ArchiveScreen()));
      case 'dna':
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const ProblemDnaScreen()));
    }
  }

  /// انتخاب پروژه برای «ماشین زمان»
  void _pickProblemThen(BuildContext context, DatabaseHelper db) async {
    final database = await db.database;
    final rows = await database.query('problems',
        columns: ['id', 'title'],
        where: 'is_archived = 0',
        orderBy: 'id DESC',
        limit: 30);
    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text('یک پروژه انتخاب کنید',
                  style: TextStyle(fontWeight: FontWeight.w900)),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final r in rows)
                    ListTile(
                      title: Text(r['title'] as String? ?? ''),
                      onTap: () {
                        Navigator.pop(ctx);
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => TimeMachineScreen(
                                    problemId: r['id'] as int)));
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

class _ToolCard extends StatelessWidget {
  const _ToolCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.desc,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String desc;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: .06),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(title,
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(desc,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 11.5, color: Colors.black54)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
