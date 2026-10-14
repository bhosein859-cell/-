import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'schema.dart';

/// آمار کلی برای داشبورد.
class DashboardStats {
  const DashboardStats({
    required this.openProblems,
    required this.pendingActions,
    required this.knowledgeArticles,
  });

  final int openProblems;
  final int pendingActions;
  final int knowledgeArticles;
}

/// مدیر مرکزی دیتابیس محلی «گره‌گشا» — کاملاً آفلاین.
///
/// - اندروید: درایور پیش‌فرض `sqflite`
/// - ویندوز/لینوکس/مک: درایور `sqflite_common_ffi`
///
/// الگوی طراحی: تک‌نمونه (Singleton) + اتصال تنبل (Lazy).
class DatabaseHelper {
  DatabaseHelper._internal();

  /// تنها نمونه‌ی این کلاس در کل اپلیکیشن
  static final DatabaseHelper instance = DatabaseHelper._internal();

  static const String dbName = 'gereh_gosha.sqlite';
  static const String dataDirName = 'GerehGosha';
  static const String attachmentsDirName = 'attachments';

  Database? _database;
  String? _dbPath;

  /// اتصال فعال؛ در صورت نیاز به‌صورت خودکار ایجاد می‌شود.
  Future<Database> get database async => _database ??= await _open();

  bool get _isDesktop =>
      Platform.isWindows || Platform.isLinux || Platform.isMacOS;

  /// پوشه‌ی داده‌ی اپلیکیشن داخل پوشه‌ی اسناد کاربر.
  Future<Directory> get dataDir async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, dataDirName));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  /// پوشه‌ی پیوست‌ها (عکس، PDF، ویدیو).
  Future<Directory> get attachmentsDir async {
    final dir = Directory(p.join((await dataDir).path, attachmentsDirName));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  /// مسیر فیزیکی فایل دیتابیس — برای پشتیبان‌گیری/بازیابی (.psp).
  Future<String> resolveDbPath() async {
    if (_dbPath == null) await database;
    return _dbPath!;
  }

  Future<Database> _open() async {
    if (_isDesktop) sqfliteFfiInit();
    final DatabaseFactory factory =
        _isDesktop ? databaseFactoryFfi : databaseFactory;

    _dbPath = p.join((await dataDir).path, dbName);
    return factory.openDatabase(
      _dbPath!,
      options: OpenDatabaseOptions(
        version: Schema.version,
        onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      ),
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    final batch = db.batch();
    Schema.createStatements.forEach(batch.execute);
    Schema.indexStatements.forEach(batch.execute);
    Schema.seedStatements.forEach(batch.execute);
    await batch.commit(noResult: true);
  }

  /// الگوی مهاجرت (Migration) برای نسخه‌های آینده:
  /// هر بار که [Schema.version] افزایش یابد، دستورات همان نسخه اینجا اجرا می‌شود.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // جداول فاز ۲: استخوان‌ماهی، پارتو، گانت
      await db.execute('''
        CREATE TABLE IF NOT EXISTS fishbone_nodes (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          problem_id INTEGER NOT NULL REFERENCES problems(id) ON DELETE CASCADE,
          parent_id INTEGER REFERENCES fishbone_nodes(id) ON DELETE CASCADE,
          title TEXT NOT NULL, category TEXT,
          level INTEGER NOT NULL DEFAULT 0,
          sort_order INTEGER NOT NULL DEFAULT 0,
          is_root_cause INTEGER NOT NULL DEFAULT 0,
          created_at TEXT NOT NULL DEFAULT (datetime('now')),
          metadata TEXT NOT NULL DEFAULT '{}'
        );''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS pareto_data (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          problem_id INTEGER NOT NULL REFERENCES problems(id) ON DELETE CASCADE,
          cause TEXT NOT NULL, frequency REAL NOT NULL,
          cumulative_percent REAL, sort_order INTEGER NOT NULL DEFAULT 0
        );''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS gantt_tasks (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          problem_id INTEGER NOT NULL REFERENCES problems(id) ON DELETE CASCADE,
          action_id INTEGER REFERENCES actions(id) ON DELETE SET NULL,
          title TEXT NOT NULL,
          start_date TEXT NOT NULL, end_date TEXT NOT NULL,
          depends_on INTEGER REFERENCES gantt_tasks(id) ON DELETE SET NULL,
          progress INTEGER NOT NULL DEFAULT 0 CHECK (progress BETWEEN 0 AND 100),
          status TEXT NOT NULL DEFAULT 'not_started',
          metadata TEXT NOT NULL DEFAULT '{}'
        );''');
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_fishbone_problem ON fishbone_nodes(problem_id);');
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_pareto_problem ON pareto_data(problem_id);');
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_gantt_problem ON gantt_tasks(problem_id);');
    }
    if (oldVersion < 3) {
      // جداول فاز ۳: تیم، FMEA، داده آماری، Pugh، پایلوت، COPQ، درس‌آموخته‌ها
      await db.execute('''
        CREATE TABLE IF NOT EXISTS team_members (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          problem_id INTEGER NOT NULL REFERENCES problems(id) ON DELETE CASCADE,
          user_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
          name TEXT NOT NULL, role TEXT NOT NULL,
          joined_at TEXT NOT NULL DEFAULT (datetime('now'))
        );''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS fmea_items (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          problem_id INTEGER NOT NULL REFERENCES problems(id) ON DELETE CASCADE,
          item_name TEXT NOT NULL, failure_mode TEXT NOT NULL, effect TEXT NOT NULL,
          s INTEGER NOT NULL CHECK (s BETWEEN 1 AND 10),
          cause TEXT NOT NULL,
          o INTEGER NOT NULL CHECK (o BETWEEN 1 AND 10),
          control TEXT,
          d INTEGER NOT NULL CHECK (d BETWEEN 1 AND 10),
          rpn INTEGER NOT NULL, proposed_action TEXT
        );''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS statistical_data (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          problem_id INTEGER NOT NULL REFERENCES problems(id) ON DELETE CASCADE,
          chart_type TEXT NOT NULL,
          data TEXT NOT NULL DEFAULT '[]', data2 TEXT NOT NULL DEFAULT '[]'
        );''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS pugh_matrix (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          problem_id INTEGER NOT NULL REFERENCES problems(id) ON DELETE CASCADE,
          solution TEXT NOT NULL, criterion TEXT NOT NULL,
          score INTEGER NOT NULL CHECK (score BETWEEN 1 AND 5),
          weight INTEGER NOT NULL CHECK (weight BETWEEN 1 AND 10)
        );''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS pilot_results (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          problem_id INTEGER NOT NULL REFERENCES problems(id) ON DELETE CASCADE,
          date TEXT NOT NULL, before REAL NOT NULL, after REAL NOT NULL,
          stat_note TEXT
        );''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS copq (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          problem_id INTEGER NOT NULL REFERENCES problems(id) ON DELETE CASCADE,
          category TEXT NOT NULL, before REAL NOT NULL, after REAL NOT NULL
        );''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS lessons_learned (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          problem_id INTEGER NOT NULL REFERENCES problems(id) ON DELETE CASCADE,
          lesson TEXT NOT NULL,
          category TEXT NOT NULL DEFAULT 'technical',
          created_at TEXT NOT NULL DEFAULT (datetime('now'))
        );''');
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_fmea_problem ON fmea_items(problem_id);');
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_team_problem ON team_members(problem_id);');
    }
    if (oldVersion < 4) {
      // فاز ۴: بایگانی، ویزارد سفارشی، رأی‌گیری و جستجوی سریع
      try {
        await db.execute(
            'ALTER TABLE problems ADD COLUMN is_archived INTEGER NOT NULL DEFAULT 0;');
      } catch (_) {}
      await db.execute('''
        CREATE TABLE IF NOT EXISTS custom_wizards (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL, industry TEXT,
          steps_json TEXT NOT NULL DEFAULT '[]',
          created_at TEXT NOT NULL DEFAULT (datetime('now'))
        );''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS polls (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          problem_id INTEGER NOT NULL REFERENCES problems(id) ON DELETE CASCADE,
          question TEXT NOT NULL,
          options TEXT NOT NULL DEFAULT '[]',
          created_at TEXT NOT NULL DEFAULT (datetime('now'))
        );''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS poll_votes (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          poll_id INTEGER NOT NULL REFERENCES polls(id) ON DELETE CASCADE,
          user_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
          option_idx INTEGER NOT NULL,
          voted_at TEXT NOT NULL DEFAULT (datetime('now'))
        );''');
      // FTS5 برای جستجوی فراگیر — در دسترس نبودن را تحمل می‌کنیم
      try {
        await db.execute('''
          CREATE VIRTUAL TABLE problems_fts USING fts5(
            title, description, content='', content_rowid='id', tokenize='unicode61');
        ''');
        await db.execute('''
          INSERT INTO problems_fts(rowid, title, description)
          SELECT id, title, COALESCE(description, '') FROM problems;
        ''');
      } catch (_) {}
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_polls_problem ON polls(problem_id);');
    }
  }

  /// بستن اتصال — قبل از کپی فایل دیتابیس برای خروجی `.psp` ضروری است.
  Future<void> close() async {
    await _database?.close();
    _database = null;
  }

  /// ثبت رویداد در تاریخچه‌ی تغییرات (Audit Trail).
  Future<int> logAudit({
    required String action,
    int? problemId,
    int userId = 1,
    String? entityType,
    int? entityId,
    Map<String, dynamic>? details,
  }) async {
    final db = await database;
    return db.insert('audit_trail', {
      'problem_id': problemId,
      'user_id': userId,
      'action': action,
      'entity_type': entityType,
      'entity_id': entityId,
      'details': details == null ? null : jsonEncode(details),
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  /// آمار داشبورد (تعداد مسائل باز، اقدامات در جریان، مقالات دانش).
  Future<DashboardStats> dashboardStats() async {
    final db = await database;
    final open = Sqflite.firstIntValue(await db.rawQuery(
            "SELECT COUNT(*) FROM problems WHERE status IN ('open','in_progress')")) ??
        0;
    final pending = Sqflite.firstIntValue(await db
            .rawQuery("SELECT COUNT(*) FROM actions WHERE status != 'done'")) ??
        0;
    final articles = Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM knowledge_base')) ??
        0;
    return DashboardStats(
      openProblems: open,
      pendingActions: pending,
      knowledgeArticles: articles,
    );
  }
}
