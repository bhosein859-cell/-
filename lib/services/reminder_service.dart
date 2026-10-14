import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database/database_helper.dart';

/// ═══════════════════════════════════════════════════════════════
/// یادآور هوشمند — شناسایی اقدامات عقب‌افتاده بر اساس اولویت
/// کاملاً آفلاین: نتیجه در داشبورد/مرکز فرمان نمایش داده می‌شود.
/// (نوتیفیکیشن سیستمی در فاز انتشار با تنظیمات بومی فعال می‌شود.)
/// ═══════════════════════════════════════════════════════════════
class ReminderService {
  ReminderService(this._db);

  final DatabaseHelper _db;

  /// اقداماتی که مهلتشان گذشته یا امروز فرا می‌رسد
  Future<List<DueAction>> overdueAndToday() async {
    final db = await _db.database;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final rows = await db.rawQuery('''
      SELECT a.id, a.title, a.due_date, a.status, a.progress,
             p.title AS problem_title, p.priority, p.level
      FROM actions a
      JOIN problems p ON p.id = a.problem_id
      WHERE a.status != 'done'
        AND a.due_date IS NOT NULL
        AND a.due_date <= ?
        AND p.is_archived = 0
      ORDER BY a.due_date ASC
    ''', [today]);

    return [
      for (final r in rows)
        DueAction(
          id: r['id'] as int,
          title: r['title'] as String? ?? '',
          problemTitle: r['problem_title'] as String? ?? '',
          dueDate: r['due_date'] as String? ?? '',
          progress: r['progress'] as int? ?? 0,
          level: r['level'] as int? ?? 1,
          priority: r['priority'] as String? ?? 'medium',
        ),
    ];
  }

  /// امتیاز فوریت برای مرتب‌سازی یادآورها (بالاتر = فوری‌تر)
  static int urgency(DueAction a) {
    final daysOverdue = DateTime.now()
        .difference(DateTime.tryParse(a.dueDate) ?? DateTime.now())
        .inDays;
    var score = daysOverdue.clamp(-30, 30) * 10;
    score += switch (a.priority) {
      'high' => 25,
      'medium' => 10,
      _ => 0,
    };
    score += a.level * 5; // مسائل سطح بالاتر، فوری‌تر
    return score;
  }
}

class DueAction {
  const DueAction({
    required this.id,
    required this.title,
    required this.problemTitle,
    required this.dueDate,
    required this.progress,
    required this.level,
    required this.priority,
  });

  final int id;
  final String title;
  final String problemTitle;
  final String dueDate;
  final int progress;
  final int level;
  final String priority;

  bool get isOverdue =>
      dueDate.compareTo(DateTime.now().toIso8601String().substring(0, 10)) < 0;
}

final reminderProvider =
    Provider<ReminderService>((ref) => ReminderService(ref.watch(databaseProvider)));
