import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/database_helper.dart';
import '../models/audit_entry.dart';
import '../models/fishbone_node.dart';
import '../models/gantt_task.dart';
import '../models/pareto_entry.dart';
import 'problem_repository.dart';

/// مخزن داده‌ی سطح ۲ — CRUD سه جدول جدید + تاریخچه.
class Level2Repository {
  Level2Repository(this._db);

  final DatabaseHelper _db;

  // ════════════════ استخوان‌ماهی ════════════════

  Future<int> insertFishboneNode(FishboneNode node) async {
    final db = await _db.database;
    return db.insert('fishbone_nodes', node.toMap());
  }

  Future<void> updateFishboneNode(int id, Map<String, Object?> values) async {
    final db = await _db.database;
    await db.update('fishbone_nodes', values, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteFishboneNode(int id) async {
    final db = await _db.database;
    await db.delete('fishbone_nodes', where: 'id = ? OR parent_id = ?', whereArgs: [id, id]);
  }

  /// همه‌ی گره‌های یک مسئله (شاخه‌های اصلی + زیرشاخه‌ها)
  Future<List<FishboneNode>> fishboneNodes(int problemId) async {
    final db = await _db.database;
    final rows = await db.query('fishbone_nodes',
        where: 'problem_id = ?', whereArgs: [problemId], orderBy: 'level, sort_order');
    return rows.map(FishboneNode.fromMap).toList();
  }

  /// ساخت شش شاخه‌ی اصلی 6M برای مسئله‌ی تازه
  Future<void> seedFishboneCategories(int problemId) async {
    for (var i = 0; i < FishboneCategory.all.length; i++) {
      await insertFishboneNode(FishboneNode(
        problemId: problemId,
        title: FishboneCategory.all[i]['fa']!,
        category: FishboneCategory.all[i]['key'],
        level: 0,
        sortOrder: i,
      ));
    }
  }

  // ════════════════ پارتو ════════════════

  /// جایگزینی کامل داده‌های پارتو (با درصد تجمعی محاسبه‌شده)
  Future<void> replacePareto(int problemId, List<ParetoEntry> computed) async {
    final db = await _db.database;
    await db.delete('pareto_data', where: 'problem_id = ?', whereArgs: [problemId]);
    for (final e in computed) {
      await db.insert('pareto_data', {
        'problem_id': problemId,
        'cause': e.cause,
        'frequency': e.frequency,
        'cumulative_percent': e.cumulativePercent,
        'sort_order': e.sortOrder,
      });
    }
  }

  Future<List<ParetoEntry>> paretoData(int problemId) async {
    final db = await _db.database;
    final rows = await db.query('pareto_data',
        where: 'problem_id = ?', whereArgs: [problemId], orderBy: 'sort_order');
    return rows.map(ParetoEntry.fromMap).toList();
  }

  // ════════════════ گانت ════════════════

  Future<int> insertGanttTask(GanttTask task) async {
    final db = await _db.database;
    return db.insert('gantt_tasks', task.toMap());
  }

  Future<void> updateGanttTask(int id, Map<String, Object?> values) async {
    final db = await _db.database;
    await db.update('gantt_tasks', values, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteGanttTask(int id) async {
    final db = await _db.database;
    await db.delete('gantt_tasks', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<GanttTask>> ganttTasks(int problemId) async {
    final db = await _db.database;
    final rows = await db.query('gantt_tasks',
        where: 'problem_id = ?', whereArgs: [problemId], orderBy: 'start_date');
    return rows.map(GanttTask.fromMap).toList();
  }

  // ════════════════ تاریخچه (پنل کناری) ════════════════

  Future<List<AuditEntry>> history(int problemId) async {
    final db = await _db.database;
    final rows = await db.query('audit_trail',
        where: 'problem_id = ?', whereArgs: [problemId], orderBy: 'id DESC', limit: 50);
    return rows.map(AuditEntry.fromMap).toList();
  }
}

final level2RepositoryProvider = Provider<Level2Repository>(
  (ref) => Level2Repository(ref.watch(databaseProvider)),
);
