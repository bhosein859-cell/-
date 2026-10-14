import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/persian_utils.dart';
import '../../data/database/database_helper.dart';

/// ═══════════════════════════════════════════════════════════════
/// جستجوی فراگیر — هم‌زمان در پروژه‌ها، اقدامات، درس‌آموخته‌ها و
/// بانک دانش؛ با فیلتر نوع/سطح و استفاده از ایندکس‌های دیتابیس.
/// ═══════════════════════════════════════════════════════════════
class GlobalSearchScreen extends ConsumerStatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  ConsumerState<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends ConsumerState<GlobalSearchScreen> {
  final _query = TextEditingController();
  String _filter = 'همه';
  List<_Hit> _hits = [];
  bool _searched = false;

  static const _filters = ['همه', 'مسئله‌ها', 'اقدامات', 'درس‌آموخته‌ها', 'بانک دانش'];

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final q = _query.text.trim();
    if (q.isEmpty) return;
    final db = await ref.read(databaseProvider).database;
    final like = '%$q%';
    final hits = <_Hit>[];

    if (_filter == 'همه' || _filter == 'مسئله‌ها') {
      // ابتدا تلاش با جدول متنی سریع (FTS5)؛ در صورت نبودن، جستجوی معمولی
      try {
        final fts = await db.rawQuery(
            "SELECT rowid FROM problems_fts WHERE problems_fts MATCH ?",
            ['"${q.replaceAll('"', ' ')}"']);
        if (fts.isNotEmpty) {
          final ids = fts.map((r) => r['rowid'] as int).toList();
          final marks = ids.map((_) => '?').join(',');
          final rows = await db.query('problems',
              columns: ['id', 'title', 'level', 'status'],
              where: 'id IN ($marks)',
              whereArgs: ids);
          hits.addAll(rows.map((r) => _Hit(
                kind: 'مسئله',
                title: r['title'] as String? ?? '',
                sub: 'سطح ${r['level']}',
                level: r['level'] as int? ?? 1,
              )));
          setState(() {
            _hits = hits;
            _searched = true;
          });
          return;
        }
      } catch (_) {}
      final rows = await db.query('problems',
          columns: ['id', 'title', 'level', 'status', 'description'],
          where: 'title LIKE ? OR description LIKE ?',
          whereArgs: [like, like]);
      hits.addAll(rows.map((r) => _Hit(
            kind: 'مسئله',
            title: r['title'] as String? ?? '',
            sub: 'سطح ${r['level']}',
            level: r['level'] as int? ?? 1,
          )));
    }
    if (_filter == 'همه' || _filter == 'اقدامات') {
      final rows = await db.query('actions',
          columns: ['title', 'status'],
          where: 'title LIKE ? OR description LIKE ?',
          whereArgs: [like, like],
          limit: 30);
      hits.addAll(rows.map((r) => _Hit(
            kind: 'اقدام',
            title: r['title'] as String? ?? '',
            sub: r['status'] as String? ?? '',
          )));
    }
    if (_filter == 'همه' || _filter == 'درس‌آموخته‌ها') {
      final rows = await db.query('lessons_learned',
          columns: ['lesson', 'category'], where: 'lesson LIKE ?',
          whereArgs: [like], limit: 30);
      hits.addAll(rows.map((r) => _Hit(
            kind: 'درس‌آموخته',
            title: r['lesson'] as String? ?? '',
            sub: r['category'] as String? ?? '',
          )));
    }
    if (_filter == 'همه' || _filter == 'بانک دانش') {
      final rows = await db.query('knowledge_base',
          columns: ['title', 'summary'],
          where: 'title LIKE ? OR summary LIKE ?',
          whereArgs: [like, like],
          limit: 30);
      hits.addAll(rows.map((r) => _Hit(
            kind: 'بانک دانش',
            title: r['title'] as String? ?? '',
            sub: r['summary'] as String? ?? '',
          )));
    }
    setState(() {
      _hits = hits;
      _searched = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('🔎 جستجوی فراگیر')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                TextField(
                  controller: _query,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'جستجو در همه‌چیز…',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: _search),
                  ),
                  onSubmitted: (_) => _search(),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final f in _filters)
                      ChoiceChip(
                        label: Text(f),
                        selected: _filter == f,
                        onSelected: (_) => setState(() => _filter = f),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: !_searched
                ? const Center(
                    child: Text('عبارتی تایپ و اینتر بزنید تا همه‌جا جستجو شود.'))
                : _hits.isEmpty
                    ? const Center(child: Text('نتیجه‌ای پیدا نشد.'))
                    : ListView.builder(
                        itemCount: _hits.length,
                        itemBuilder: (context, i) {
                          final h = _hits[i];
                          return ListTile(
                            leading: Icon(_iconOf(h.kind),
                                color: _colorOf(h.kind)),
                            title: Text(h.title),
                            subtitle: Text('${h.kind} • ${h.sub}'),
                            trailing: h.level > 0
                                ? Chip(
                                    label: Text('سطح ${PersianUtils.faDigits('${h.level}')}'),
                                    visualDensity: VisualDensity.compact,
                                  )
                                : null,
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  IconData _iconOf(String kind) => switch (kind) {
        'مسئله' => Icons.flag_outlined,
        'اقدام' => Icons.checklist,
        'درس‌آموخته' => Icons.lightbulb_outline,
        _ => Icons.menu_book_outlined,
      };

  Color _colorOf(String kind) => switch (kind) {
        'مسئله' => AppColors.navyBlue,
        'اقدام' => AppColors.level2,
        'درس‌آموخته' => AppColors.orange,
        _ => AppColors.success,
      };
}

class _Hit {
  const _Hit({required this.kind, required this.title, required this.sub, this.level = 0});

  final String kind;
  final String title;
  final String sub;
  final int level;
}
