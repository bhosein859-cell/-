import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database/database_helper.dart';

/// ═══════════════════════════════════════════════════════════════
/// گیمیفیکیشن گره‌گشا — امتیازدهی، نشان‌های دیجیتال و جدول رتبه‌بندی
/// ═══════════════════════════════════════════════════════════════
class GamificationService {
  GamificationService(this._db);

  final DatabaseHelper _db;

  /// جدول نشان‌ها: کلید ← (نام، شرح، آیکون، شرط امتیازی)
  static const Map<String, BadgeDef> badges = {
    'first_fix': BadgeDef('اولین گره', 'بستن اولین مسئله', '🎯'),
    'fast_solver': BadgeDef('حل‌کننده سریع', 'حل مسئله در کمتر از ۳ روز', '⚡'),
    'root_master': BadgeDef('ریشه‌یاب ماهر', '۵ مسئله با ریشه‌یابی کامل (۵ چرا)', '🌳'),
    'team_leader': BadgeDef('رهبر تیم برتر', 'رهبری ۳ پروژه‌ی تیمی موفق', '🧭'),
    'saver': BadgeDef('قهرمان صرفه‌جویی', 'ثبت صرفه‌جویی مالی در یک پروژه', '💰'),
    'streak_3': BadgeDef('زنجیره‌ی سه‌تایی', 'بستن ۳ مسئله پشت سر هم', '🔥'),
    'knowledge_keeper': BadgeDef('نگهبان دانش', 'ثبت ۵ درس‌آموخته در بانک دانش', '📚'),
    'level3_hero': BadgeDef('قهرمان سطح ۳', 'بستن یک پروژه‌ی گسترده و بحرانی', '🏆'),
  };

  /// محاسبه‌ی امتیاز و نشان‌های یک کاربر
  Future<UserScore> scoreOf(int userId) async {
    final db = await _db.database;

    final closed = await db.rawQuery(
        "SELECT id, created_at, resolved_at, metadata, level FROM problems "
        "WHERE status = 'closed' AND owner_id = ?", [userId]);
    final lessonsCount = (await db.rawQuery('''
      SELECT COUNT(*) AS c FROM lessons_learned l
      JOIN problems p ON p.id = l.problem_id
      WHERE p.owner_id = ?
    ''', [userId])).first['c'] as int? ?? 0;

    var points = 0;
    var fast = 0, withWhys = 0, savings = 0, level3 = 0;

    for (final p in closed) {
      points += (p['level'] as int? ?? 1) * 10; // سطح بالاتر = امتیاز بیشتر
      final createdAt = DateTime.tryParse(p['created_at'] as String? ?? '');
      final resolvedAt = DateTime.tryParse(p['resolved_at'] as String? ?? '');
      if (createdAt != null &&
          resolvedAt != null &&
          resolvedAt.difference(createdAt).inDays < 3) {
        fast++;
      }
      final meta =
          jsonDecode(p['metadata'] as String? ?? '{}') as Map<String, dynamic>;
      final whys = (meta['whys_tree'] as List? ?? const []).length;
      if (whys >= 5) withWhys++;
      if ((meta['team_score'] as int? ?? 0) > 60) savings++;
      if ((p['level'] as int? ?? 1) == 3) level3++;
    }
    points += closed.length * 5 + lessonsCount * 3 + fast * 8;

    final earned = <String, String>{};
    if (closed.isNotEmpty) earned['first_fix'] = badges['first_fix']!.icon;
    if (fast > 0) earned['fast_solver'] = badges['fast_solver']!.icon;
    if (withWhys >= 5) earned['root_master'] = badges['root_master']!.icon;
    if (closed.where((p) => (p['level'] as int) >= 2).length >= 3) {
      earned['team_leader'] = badges['team_leader']!.icon;
    }
    if (savings > 0) earned['saver'] = badges['saver']!.icon;
    if (closed.length >= 3) earned['streak_3'] = badges['streak_3']!.icon;
    if (lessonsCount >= 5) {
      earned['knowledge_keeper'] = badges['knowledge_keeper']!.icon;
    }
    if (level3 > 0) earned['level3_hero'] = badges['level3_hero']!.icon;

    return UserScore(
        userId: userId, points: points, closedCount: closed.length,
        earnedBadges: earned);
  }

  /// جدول رتبه‌بندی همه‌ی کاربران فعال
  Future<List<UserScore>> leaderboard() async {
    final db = await _db.database;
    final users = await db.query('users', where: 'is_active = 1');
    final scores = <UserScore>[];
    for (final u in users) {
      final s = await scoreOf(u['id'] as int);
      scores.add(UserScore(
        userId: u['id'] as int,
        displayName: u['full_name'] as String? ?? u['username'] as String? ?? '',
        points: s.points,
        closedCount: s.closedCount,
        earnedBadges: s.earnedBadges,
      ));
    }
    scores.sort((a, b) => b.points.compareTo(a.points));
    return scores;
  }
}

class BadgeDef {
  const BadgeDef(this.name, this.desc, this.icon);

  final String name;
  final String desc;
  final String icon; // ایموجی — بدون وابستگی به فونت آیکون خارجی
}

class UserScore {
  const UserScore({
    required this.userId,
    this.displayName = '',
    required this.points,
    required this.closedCount,
    required this.earnedBadges,
  });

  final int userId;
  final String displayName;
  final int points;
  final int closedCount;
  final Map<String, String> earnedBadges;
}

final gamificationProvider = Provider<GamificationService>(
  (ref) => GamificationService(ref.watch(databaseProvider)),
);
