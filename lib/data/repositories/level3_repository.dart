import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/database_helper.dart';
import '../models/level3_models.dart';
import 'problem_repository.dart';

/// مخزن داده‌ی سطح ۳ — CRUD هفت جدول جدید.
class Level3Repository {
  Level3Repository(this._db);

  final DatabaseHelper _db;

  // ── تیم ──
  Future<int> addTeamMember(TeamMemberL3 m) async =>
      _db.database.then((db) => db.insert('team_members', m.toMap()));

  Future<void> removeTeamMember(int id) async => (await _db.database)
      .delete('team_members', where: 'id = ?', whereArgs: [id]);

  Future<List<TeamMemberL3>> team(int problemId) async =>
      (await (await _db.database).query('team_members',
              where: 'problem_id = ?', whereArgs: [problemId], orderBy: 'id'))
          .map(TeamMemberL3.fromMap)
          .toList();

  // ── FMEA ──
  Future<int> insertFmea(FmeaItem f) async =>
      _db.database.then((db) => db.insert('fmea_items', f.toMap()));

  Future<void> updateFmea(int id, Map<String, Object?> v) async =>
      (await _db.database).update('fmea_items', v, where: 'id = ?', whereArgs: [id]);

  Future<void> deleteFmea(int id) async =>
      (await _db.database).delete('fmea_items', where: 'id = ?', whereArgs: [id]);

  Future<List<FmeaItem>> fmea(int problemId) async =>
      (await (await _db.database).query('fmea_items',
              where: 'problem_id = ?', whereArgs: [problemId], orderBy: 'rpn DESC'))
          .map(FmeaItem.fromMap)
          .toList();

  // ── داده آماری ──
  Future<void> saveStat(int problemId, String chartType, List<double> values,
      [List<double> values2 = const []]) async {
    final db = await _db.database;
    await db.delete('statistical_data',
        where: 'problem_id = ? AND chart_type = ?', whereArgs: [problemId, chartType]);
    await db.insert('statistical_data',
        StatisticalData(problemId: problemId, chartType: chartType, values: values, values2: values2)
            .toMap());
  }

  Future<Map<String, StatisticalData>> stats(int problemId) async {
    final rows = await (await _db.database).query('statistical_data',
        where: 'problem_id = ?', whereArgs: [problemId]);
    return {
      for (final r in rows.map(StatisticalData.fromMap)) r.chartType: r,
    };
  }

  // ── Pugh ──
  Future<void> replacePugh(int problemId, List<PughCell> cells) async {
    final db = await _db.database;
    await db.delete('pugh_matrix', where: 'problem_id = ?', whereArgs: [problemId]);
    for (final c in cells) {
      await db.insert('pugh_matrix', c.toMap());
    }
  }

  Future<List<PughCell>> pugh(int problemId) async =>
      (await (await _db.database).query('pugh_matrix',
              where: 'problem_id = ?', whereArgs: [problemId]))
          .map(PughCell.fromMap)
          .toList();

  // ── Pilot ─
  Future<int> addPilot(PilotResult p) async =>
      _db.database.then((db) => db.insert('pilot_results', p.toMap()));

  Future<List<PilotResult>> pilots(int problemId) async =>
      (await (await _db.database).query('pilot_results',
              where: 'problem_id = ?', whereArgs: [problemId], orderBy: 'date'))
          .map(PilotResult.fromMap)
          .toList();

  // ── COPQ ──
  Future<void> replaceCopq(int problemId, List<CopqRow> rows) async {
    final db = await _db.database;
    await db.delete('copq', where: 'problem_id = ?', whereArgs: [problemId]);
    for (final r in rows) {
      await db.insert('copq', r.toMap());
    }
  }

  Future<List<CopqRow>> copq(int problemId) async =>
      (await (await _db.database)
              .query('copq', where: 'problem_id = ?', whereArgs: [problemId]))
          .map(CopqRow.fromMap)
          .toList();

  // ── درس‌آموخته‌ها ──
  Future<int> addLesson(LessonLearned l) async =>
      _db.database.then((db) => db.insert('lessons_learned', l.toMap()));

  Future<List<LessonLearned>> lessons(int problemId) async =>
      (await (await _db.database).query('lessons_learned',
              where: 'problem_id = ?', whereArgs: [problemId], orderBy: 'id'))
          .map(LessonLearned.fromMap)
          .toList();
}

final level3RepositoryProvider = Provider<Level3Repository>(
  (ref) => Level3Repository(ref.watch(databaseProvider)),
);
