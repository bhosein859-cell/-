import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/app_providers.dart';
import '../database/database_helper.dart';
import '../models/action_item.dart';
import '../models/attachment.dart';
import '../models/problem.dart';

/// مخزن دسترسی به داده برای مسائل، اقدامات و پیوست‌ها (لایه‌ی Repository).
///
/// تمام عملیات SQL فاز ۱ در این کلاس متمرکز است تا صفحات UI
/// هیچ‌گاه مستقیماً با دیتابیس صحبت نکنند.
class ProblemRepository {
  ProblemRepository(this._db);

  final DatabaseHelper _db;

  // ════════════════════════════ مسائل ════════════════════════════

  /// درج مسئله و ثبت رویداد در تاریخچه. شناسه‌ی سطر برمی‌گردد.
  Future<int> insertProblem(Problem problem) async {
    final db = await _db.database;
    final id = await db.insert('problems', problem.toMap());
    await _db.logAudit(
      action: 'create_problem',
      problemId: id,
      entityType: 'problem',
      entityId: id,
      details: {'title': problem.title, 'level': problem.level},
    );
    return id;
  }

  /// به‌روزرسانی عمومی ستون‌های مسئله (updated_at خودکار ثبت می‌شود).
  Future<void> updateProblem(int id, Map<String, Object?> values) async {
    final db = await _db.database;
    final withTime = Map<String, Object?>.from(values)
      ..['updated_at'] = DateTime.now().toIso8601String();
    await db.update('problems', withTime, where: 'id = ?', whereArgs: [id]);
    await _db.logAudit(
      action: 'update_problem',
      problemId: id,
      entityType: 'problem',
      entityId: id,
      details: {'fields': values.keys.toList()},
    );
  }

  Future<Problem?> getProblem(int id) async {
    final db = await _db.database;
    final rows =
        await db.query('problems', where: 'id = ?', whereArgs: [id]);
    return rows.isEmpty ? null : Problem.fromMap(rows.first);
  }

  /// لیست مسائل (به‌تازگی ثبت) — برای «پروژه‌های فعال» و داشبورد.
  Future<List<Problem>> getAllProblems({int? limit}) async {
    final db = await _db.database;
    final rows = await db.query(
      'problems',
      orderBy: 'created_at DESC, id DESC',
      limit: limit,
    );
    return rows.map(Problem.fromMap).toList();
  }

  /// ادغام کلیدهای جدید در ستون metadata (بدون شکستن داده‌های قبلی).
  Future<void> mergeProblemMetadata(
      int id, Map<String, dynamic> extra) async {
    final problem = await getProblem(id);
    if (problem == null) return;
    final meta = Map<String, dynamic>.from(problem.metadata)..addAll(extra);
    await updateProblem(id, {'metadata': jsonEncode(meta)});
  }

  // ════════════════════════════ اقدامات ════════════════════════════

  Future<int> insertAction(ActionItem action) async {
    final db = await _db.database;
    final id = await db.insert('actions', action.toMap());
    await _db.logAudit(
      action: 'create_action',
      problemId: action.problemId,
      entityType: 'action',
      entityId: id,
      details: {'title': action.title},
    );
    return id;
  }

  Future<void> updateAction(int id, Map<String, Object?> values) async {
    final db = await _db.database;
    await db.update('actions', values, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<ActionItem>> actionsForProblem(int problemId) async {
    final db = await _db.database;
    final rows = await db.query(
      'actions',
      where: 'problem_id = ?',
      whereArgs: [problemId],
      orderBy: 'id ASC',
    );
    return rows.map(ActionItem.fromMap).toList();
  }

  /// تبدیل پروژه به بانک دانش (گام‌های پایانی سطح ۳)
  Future<void> insertKnowledgeFromProject({
    required int problemId,
    required String title,
    required String summary,
    required List<String> tags,
  }) async {
    final db = await _db.database;
    await db.insert('knowledge_base', {
      'problem_id': problemId,
      'title': title,
      'summary': summary,
      'tags': jsonEncode(tags),
      'category': 'سطح ۳',
      'author_id': 1,
    });
  }

  // ════════════════════════════ پیوست‌ها ════════════════════════════

  Future<int> insertAttachment(Attachment attachment) async {
    final db = await _db.database;
    return db.insert('attachments', attachment.toMap());
  }

  Future<List<Attachment>> attachmentsForProblem(int problemId) async {
    final db = await _db.database;
    final rows = await db.query(
      'attachments',
      where: 'problem_id = ?',
      whereArgs: [problemId],
      orderBy: 'id ASC',
    );
    return rows.map(Attachment.fromMap).toList();
  }
}

/// ارائه‌دهنده‌ی سراسری مخزن
final problemRepositoryProvider = Provider<ProblemRepository>(
  (ref) => ProblemRepository(ref.watch(databaseProvider)),
);
