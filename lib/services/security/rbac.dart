import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database/database_helper.dart';

/// ═══════════════════════════════════════════════════════════════
/// سطوح دسترسی مبتنی بر نقش (RBAC) — آفلاین و محلی
/// نقش‌ها: مدیر (Admin) > ویرایشگر (Editor) > بازدیدکننده (Viewer)
/// ═══════════════════════════════════════════════════════════════
class Rbac {
  Rbac(this._db, {this.currentUserId = 1});

  final DatabaseHelper _db;
  final int currentUserId;

  static const String admin = 'admin';
  static const String editor = 'editor';
  static const String viewer = 'viewer';
  static const String member = 'member'; // نقش پیش‌فرض = ویرایشگر

  static const Map<String, String> faLabels = {
    admin: 'مدیر',
    editor: 'ویرایشگر',
    viewer: 'بازدیدکننده',
    member: 'عضو تیم',
  };

  Future<String> _roleOf(int userId) async {
    final db = await _db.database;
    final rows =
        await db.query('users', columns: ['role'], where: 'id = ?', whereArgs: [userId]);
    return rows.isEmpty ? viewer : (rows.first['role'] as String? ?? member);
  }

  /// آیا کاربر فعلی می‌تواند این کار را انجام دهد؟
  Future<bool> can(Permission permission) async {
    final role = await _roleOf(currentUserId);
    return switch (role) {
      admin => true,
      editor || member => permission != Permission.manageUsers &&
          permission != Permission.restoreBackup &&
          permission != Permission.deleteProject,
      _ => false, // بازدیدکننده فقط مشاهده
    };
  }

  /// نسخه‌ی همگام برای چیدمان (با نقش کش‌شده)
  bool canSync(String role, Permission permission) => switch (role) {
        admin => true,
        editor || member => permission != Permission.manageUsers &&
            permission != Permission.restoreBackup &&
            permission != Permission.deleteProject,
        _ => false,
      };

  /// افزودن/ویرایش نقش کاربر — فقط مدیر مجاز است
  Future<String?> setUserRole(int userId, String newRole) async {
    if (!await can(Permission.manageUsers)) {
      return 'فقط مدیر می‌تواند سطح دسترسی تغییر دهد.';
    }
    final db = await _db.database;
    await db.update('users', {'role': newRole}, where: 'id = ?', whereArgs: [userId]);
    return null;
  }

  Future<List<UserRoleRow>> allUsers() async {
    final db = await _db.database;
    final rows = await db.query('users', where: 'is_active = 1');
    return [
      for (final r in rows)
        UserRoleRow(
          id: r['id'] as int,
          fullName: r['full_name'] as String? ?? r['username'] as String? ?? '',
          role: r['role'] as String? ?? member,
        ),
    ];
  }
}

/// فهرست مجوزهای قابل بررسی در هر صفحه
enum Permission {
  createProblem,
  editProblem,
  deleteProject,
  approveContainment,
  exportReports,
  manageUsers,
  restoreBackup,
  createBackup,
}

class UserRoleRow {
  const UserRoleRow(
      {required this.id, required this.fullName, required this.role});

  final int id;
  final String fullName;
  final String role;

  String get roleFa => Rbac.faLabels[role] ?? role;
}

final rbacProvider = Provider<Rbac>((ref) => Rbac(ref.watch(databaseProvider)));
