import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database/database_helper.dart';
import '../data/models/problem.dart';
import '../data/repositories/problem_repository.dart';

/// ═══════════════════════════════════════════════════════════════
/// کپی از پروژه به عنوان قالب — ساختار و ابزارها منتقل می‌شوند
/// اما داده‌های اجرایی (مقادیر، پیوست‌ها، تاریخ‌ها) پاک می‌مانند.
/// ═══════════════════════════════════════════════════════════════
class TemplateService {
  TemplateService(this._db, this._problems);

  final DatabaseHelper _db;
  final ProblemRepository _problems;

  /// ساخت قالب از یک مسئله‌ی موجود
  Future<int> createTemplateFrom(int problemId) async {
    final db = await _db.database;
    final rows = await db.query('problems', where: 'id = ?', whereArgs: [problemId]);
    if (rows.isEmpty) throw StateError('مسئله پیدا نشد.');
    final src = rows.first;
    final meta =
        jsonDecode(src['metadata'] as String? ?? '{}') as Map<String, dynamic>;

    // فقط «ساختار» نگه داشته می‌شود: تعریف ۵و۲اچ، دسته‌ها، ابزارها
    final structure = <String, dynamic>{
      'is_template': true,
      'source_problem_id': problemId,
      'def_5w2h': const {
        'what': '', 'why': '', 'where': '', 'when': '',
        'who': '', 'how': '', 'how_much': '',
      },
      if (meta['category'] != null) 'category': meta['category'],
    };

    return _problems.insertProblem(Problem(
      title: '${src['title']} (الگو)',
      description: 'الگوی ساخته‌شده از مسئله‌ی ${src['id']}',
      level: src['level'] as int? ?? 1,
      status: ProblemStatus.open,
      priority: src['priority'] as String? ?? 'medium',
      methodology: src['methodology'] as String?,
      ownerId: src['owner_id'] as int?,
      createdBy: src['created_by'] as int?,
      metadata: structure,
    ));
  }

  /// شروع مسئله‌ی جدید از روی یک قالب
  Future<int> startFromTemplate(int templateId, String newTitle) async {
    final db = await _db.database;
    final rows = await db.query('problems', where: 'id = ?', whereArgs: [templateId]);
    if (rows.isEmpty) throw StateError('قالب پیدا نشد.');
    final src = rows.first;
    final meta =
        jsonDecode(src['metadata'] as String? ?? '{}') as Map<String, dynamic>;
    meta.remove('is_template');
    meta.remove('source_problem_id');

    final id = await _problems.insertProblem(Problem(
      title: newTitle.trim().isEmpty
          ? (src['title'] as String).replaceAll(' (الگو)', '')
          : newTitle.trim(),
      level: src['level'] as int? ?? 1,
      status: ProblemStatus.open,
      priority: src['priority'] as String? ?? 'medium',
      methodology: src['methodology'] as String?,
      ownerId: 1,
      createdBy: 1,
      metadata: meta,
    ));

    // کپی ساختار اقدامات بدون وضعیت
    final actions = await db.query('actions',
        columns: ['title', 'description', 'phase'],
        where: 'problem_id = ?',
        whereArgs: [templateId]);
    for (final a in actions) {
      await db.insert('actions', {
        'problem_id': id,
        'title': a['title'],
        'description': a['description'],
        'phase': a['phase'],
        'status': 'pending',
        'progress': 0,
      });
    }
    return id;
  }

  /// فهرست قالب‌ها
  Future<List<Map<String, Object?>>> listTemplates() async {
    final db = await _db.database;
    return db.query('problems',
        where: "metadata LIKE '%\"is_template\":true%'",
        orderBy: 'updated_at DESC');
  }
}

final templateServiceProvider = Provider<TemplateService>(
  (ref) => TemplateService(
      ref.watch(databaseProvider), ref.watch(problemRepositoryProvider)),
);
