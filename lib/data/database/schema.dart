/// اسکیمای دیتابیس «گره‌گشا» — فاز صفر (نسخه ۱).
///
/// اصول طراحی برای پشتیبانی از ۶۶ ویژگی آینده:
///  ۱. هر جدول تجاری یک ستون `metadata` از نوع متنِ JSON دارد؛
///     ویژگی‌های آینده بدون تغییر ساختار، داده‌ی خود را آنجا ذخیره می‌کنند.
///  ۲. جدول `feature_flags` برای روشن/خاموش کردن تدریجی قابلیت‌ها.
///  ۳. جدول `app_settings` برای کلید/مقدارهای پیکربندی داخل دیتابیس.
///  ۴. مهاجرت‌ها بر اساس شماره نسخه در [DatabaseHelper._onUpgrade] اعمال می‌شوند.
library;

class Schema {
  Schema._();

  /// نسخه‌ی فعلی اسکیمای دیتابیس
  static const int version = 4;

  /// دستورات ایجاد جداول
  static const List<String> createStatements = [
    // ─────────────────────────── کاربران ───────────────────────────
    '''
    CREATE TABLE IF NOT EXISTS users (
      id            INTEGER PRIMARY KEY AUTOINCREMENT,
      username      TEXT    NOT NULL UNIQUE,
      full_name     TEXT    NOT NULL,
      role          TEXT    NOT NULL DEFAULT 'member', -- admin | manager | member
      avatar_path   TEXT,                              -- مسیر تصویر پروفایل
      password_hash TEXT,                              -- هش رمز عبور محلی
      salt          TEXT,
      is_active     INTEGER NOT NULL DEFAULT 1,
      created_at    TEXT    NOT NULL DEFAULT (datetime('now')),
      updated_at    TEXT,
      metadata      TEXT    NOT NULL DEFAULT '{}'      -- JSON انعطاف‌پذیر
    );
    ''',

    // ─────────────────────────── مسائل ─────────────────────────────
    '''
    CREATE TABLE IF NOT EXISTS problems (
      id          INTEGER PRIMARY KEY AUTOINCREMENT,
      code        TEXT    UNIQUE,                      -- کد یکتا مثل PRB-0001
      title       TEXT    NOT NULL,
      description TEXT,
      level       INTEGER NOT NULL CHECK (level IN (1, 2, 3)), -- ۱=سریع ۲=تیمی ۳=استراتژیک
      status      TEXT    NOT NULL DEFAULT 'open',     -- open | in_progress | resolved | closed
      priority    TEXT    NOT NULL DEFAULT 'medium',   -- low | medium | high | critical
      owner_id    INTEGER REFERENCES users(id) ON DELETE SET NULL, -- مسئول مسئله
      created_by  INTEGER REFERENCES users(id) ON DELETE SET NULL,
      methodology TEXT,                                -- PDCA | 8D | DMAIC | ... (فازهای بعد)
      due_date    TEXT,
      resolved_at TEXT,
      created_at  TEXT    NOT NULL DEFAULT (datetime('now')),
      updated_at  TEXT,
      metadata    TEXT    NOT NULL DEFAULT '{}'        -- DNA مسئله، نتایج ۵چرا و... در آینده
    );
    ''',

    // ─────────────────────────── اقدامات ───────────────────────────
    '''
    CREATE TABLE IF NOT EXISTS actions (
      id           INTEGER PRIMARY KEY AUTOINCREMENT,
      problem_id   INTEGER NOT NULL REFERENCES problems(id) ON DELETE CASCADE,
      title        TEXT    NOT NULL,                   -- شرح اقدام
      description  TEXT,
      phase        TEXT,                               -- فاز متدولوژی (مثل Plan/Do/Check/Act)
      assignee_id  INTEGER REFERENCES users(id) ON DELETE SET NULL, -- مسئول اقدام
      status       TEXT    NOT NULL DEFAULT 'pending', -- pending | in_progress | done | blocked
      progress     INTEGER NOT NULL DEFAULT 0 CHECK (progress BETWEEN 0 AND 100),
      due_date     TEXT,                               -- مهلت انجام
      completed_at TEXT,
      created_at   TEXT    NOT NULL DEFAULT (datetime('now')),
      metadata     TEXT    NOT NULL DEFAULT '{}'
    );
    ''',

    // ─────────────────────────── پیوست‌ها ──────────────────────────
    '''
    CREATE TABLE IF NOT EXISTS attachments (
      id          INTEGER PRIMARY KEY AUTOINCREMENT,
      problem_id  INTEGER NOT NULL REFERENCES problems(id) ON DELETE CASCADE,
      file_name   TEXT    NOT NULL,
      file_path   TEXT    NOT NULL,                    -- مسیر نسبی داخل پوشه‌ی attachments
      mime_type   TEXT,
      size_bytes  INTEGER,
      uploaded_by INTEGER REFERENCES users(id) ON DELETE SET NULL,
      created_at  TEXT    NOT NULL DEFAULT (datetime('now')),
      metadata    TEXT    NOT NULL DEFAULT '{}'
    );
    ''',

    // ──────────────────── تاریخچه‌ی تغییرات ────────────────────────
    '''
    CREATE TABLE IF NOT EXISTS audit_trail (
      id          INTEGER PRIMARY KEY AUTOINCREMENT,
      problem_id  INTEGER REFERENCES problems(id) ON DELETE CASCADE,
      user_id     INTEGER REFERENCES users(id) ON DELETE SET NULL,
      action      TEXT    NOT NULL,                    -- create | update | delete | export_psp | import_psp | ...
      entity_type TEXT,                                -- problem | action | attachment | kb | ...
      entity_id   INTEGER,
      details     TEXT,                                -- JSON جزئیات/تفاوت‌ها
      created_at  TEXT    NOT NULL DEFAULT (datetime('now'))
    );
    ''',

    // ─────────────────────────── بانک دانش ─────────────────────────
    '''
    CREATE TABLE IF NOT EXISTS knowledge_base (
      id         INTEGER PRIMARY KEY AUTOINCREMENT,
      problem_id INTEGER REFERENCES problems(id) ON DELETE SET NULL,
      title      TEXT    NOT NULL,
      summary    TEXT,                                 -- خلاصه‌ی راه‌حل
      solution   TEXT,                                 -- شرح کامل راه‌حل
      tags       TEXT    NOT NULL DEFAULT '[]',        -- آرایه‌ی JSON از برچسب‌ها
      category   TEXT,
      author_id  INTEGER REFERENCES users(id) ON DELETE SET NULL,
      created_at TEXT    NOT NULL DEFAULT (datetime('now')),
      metadata   TEXT    NOT NULL DEFAULT '{}'
    );
    ''',

    // ──────────────── جدول‌های زیرساختی/آینده ─────────────────────
    '''
    CREATE TABLE IF NOT EXISTS app_settings (
      key        TEXT PRIMARY KEY,
      value      TEXT,
      updated_at TEXT NOT NULL DEFAULT (datetime('now'))
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS feature_flags (
      feature_key TEXT PRIMARY KEY,
      name_fa     TEXT,
      enabled     INTEGER NOT NULL DEFAULT 0
    );
    ''',

    // ═══════════ جداول فاز ۲ (سطح ۲ — تیمی و تحلیلی) ═══════════

    // ─────────────────── گره‌های استخوان‌ماهی ───────────────────
    '''
    CREATE TABLE IF NOT EXISTS fishbone_nodes (
      id            INTEGER PRIMARY KEY AUTOINCREMENT,
      problem_id    INTEGER NOT NULL REFERENCES problems(id) ON DELETE CASCADE,
      parent_id     INTEGER REFERENCES fishbone_nodes(id) ON DELETE CASCADE,
      title         TEXT    NOT NULL,
      category      TEXT,                              -- man|machine|material|method|environment|management
      level         INTEGER NOT NULL DEFAULT 0,        -- 0=شاخه اصلی 6M، 1+=زیرشاخه
      sort_order    INTEGER NOT NULL DEFAULT 0,
      is_root_cause INTEGER NOT NULL DEFAULT 0,
      created_at    TEXT    NOT NULL DEFAULT (datetime('now')),
      metadata      TEXT    NOT NULL DEFAULT '{}'
    );
    ''',

    // ─────────────────── داده‌های نمودار پارتو ──────────────────
    '''
    CREATE TABLE IF NOT EXISTS pareto_data (
      id                 INTEGER PRIMARY KEY AUTOINCREMENT,
      problem_id         INTEGER NOT NULL REFERENCES problems(id) ON DELETE CASCADE,
      cause              TEXT    NOT NULL,
      frequency          REAL    NOT NULL,
      cumulative_percent REAL,                         -- درصد تجمعی (محاسبه‌ی خودکار)
      sort_order         INTEGER NOT NULL DEFAULT 0
    );
    ''',

    // ─────────────────── نوارهای گانت چارت ─────────────────────
    '''
    CREATE TABLE IF NOT EXISTS gantt_tasks (
      id         INTEGER PRIMARY KEY AUTOINCREMENT,
      problem_id INTEGER NOT NULL REFERENCES problems(id) ON DELETE CASCADE,
      action_id  INTEGER REFERENCES actions(id) ON DELETE SET NULL,
      title      TEXT    NOT NULL,
      start_date TEXT    NOT NULL,
      end_date   TEXT    NOT NULL,
      depends_on INTEGER REFERENCES gantt_tasks(id) ON DELETE SET NULL,
      progress   INTEGER NOT NULL DEFAULT 0 CHECK (progress BETWEEN 0 AND 100),
      status     TEXT    NOT NULL DEFAULT 'not_started',
      metadata   TEXT    NOT NULL DEFAULT '{}'
    );
    ''',

    // ═══════════ جداول فاز ۳ (سطح ۳ — گسترده و بحرانی) ═══════════

    '''
    CREATE TABLE IF NOT EXISTS team_members (
      id         INTEGER PRIMARY KEY AUTOINCREMENT,
      problem_id INTEGER NOT NULL REFERENCES problems(id) ON DELETE CASCADE,
      user_id    INTEGER REFERENCES users(id) ON DELETE SET NULL,
      name       TEXT    NOT NULL,
      role       TEXT    NOT NULL,
      joined_at  TEXT    NOT NULL DEFAULT (datetime('now'))
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS fmea_items (
      id              INTEGER PRIMARY KEY AUTOINCREMENT,
      problem_id      INTEGER NOT NULL REFERENCES problems(id) ON DELETE CASCADE,
      item_name       TEXT    NOT NULL,
      failure_mode    TEXT    NOT NULL,
      effect          TEXT    NOT NULL,
      s               INTEGER NOT NULL CHECK (s BETWEEN 1 AND 10),
      cause           TEXT    NOT NULL,
      o               INTEGER NOT NULL CHECK (o BETWEEN 1 AND 10),
      control         TEXT,
      d               INTEGER NOT NULL CHECK (d BETWEEN 1 AND 10),
      rpn             INTEGER NOT NULL,
      proposed_action TEXT
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS statistical_data (
      id         INTEGER PRIMARY KEY AUTOINCREMENT,
      problem_id INTEGER NOT NULL REFERENCES problems(id) ON DELETE CASCADE,
      chart_type TEXT    NOT NULL,
      data       TEXT    NOT NULL DEFAULT '[]',
      data2      TEXT    NOT NULL DEFAULT '[]'
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS pugh_matrix (
      id         INTEGER PRIMARY KEY AUTOINCREMENT,
      problem_id INTEGER NOT NULL REFERENCES problems(id) ON DELETE CASCADE,
      solution   TEXT    NOT NULL,
      criterion  TEXT    NOT NULL,
      score      INTEGER NOT NULL CHECK (score BETWEEN 1 AND 5),
      weight     INTEGER NOT NULL CHECK (weight BETWEEN 1 AND 10)
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS pilot_results (
      id         INTEGER PRIMARY KEY AUTOINCREMENT,
      problem_id INTEGER NOT NULL REFERENCES problems(id) ON DELETE CASCADE,
      date       TEXT    NOT NULL,
      before     REAL    NOT NULL,
      after      REAL    NOT NULL,
      stat_note  TEXT
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS copq (
      id         INTEGER PRIMARY KEY AUTOINCREMENT,
      problem_id INTEGER NOT NULL REFERENCES problems(id) ON DELETE CASCADE,
      category   TEXT    NOT NULL,
      before     REAL    NOT NULL,
      after      REAL    NOT NULL
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS lessons_learned (
      id         INTEGER PRIMARY KEY AUTOINCREMENT,
      problem_id INTEGER NOT NULL REFERENCES problems(id) ON DELETE CASCADE,
      lesson     TEXT    NOT NULL,
      category   TEXT    NOT NULL DEFAULT 'technical',
      created_at TEXT    NOT NULL DEFAULT (datetime('now'))
    );
    ''',

    // ═══════════ جداول فاز ۴ (ویژگی‌های هوشمند) ═══════════

    '''
    CREATE TABLE IF NOT EXISTS custom_wizards (
      id          INTEGER PRIMARY KEY AUTOINCREMENT,
      name        TEXT    NOT NULL,
      industry    TEXT,
      steps_json  TEXT    NOT NULL DEFAULT '[]',
      created_at  TEXT    NOT NULL DEFAULT (datetime('now'))
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS polls (
      id         INTEGER PRIMARY KEY AUTOINCREMENT,
      problem_id INTEGER NOT NULL REFERENCES problems(id) ON DELETE CASCADE,
      question   TEXT    NOT NULL,
      options    TEXT    NOT NULL DEFAULT '[]',
      created_at TEXT    NOT NULL DEFAULT (datetime('now'))
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS poll_votes (
      id         INTEGER PRIMARY KEY AUTOINCREMENT,
      poll_id    INTEGER NOT NULL REFERENCES polls(id) ON DELETE CASCADE,
      user_id    INTEGER REFERENCES users(id) ON DELETE SET NULL,
      option_idx INTEGER NOT NULL,
      voted_at   TEXT    NOT NULL DEFAULT (datetime('now'))
    );
    ''',
  ];

  /// ایندکس‌ها برای کارایی در مقیاس بزرگ
  static const List<String> indexStatements = [
    'CREATE INDEX IF NOT EXISTS idx_problems_status  ON problems(status);',
    'CREATE INDEX IF NOT EXISTS idx_problems_level   ON problems(level);',
    'CREATE INDEX IF NOT EXISTS idx_problems_owner   ON problems(owner_id);',
    'CREATE INDEX IF NOT EXISTS idx_actions_problem  ON actions(problem_id);',
    'CREATE INDEX IF NOT EXISTS idx_actions_status   ON actions(status);',
    'CREATE INDEX IF NOT EXISTS idx_attach_problem   ON attachments(problem_id);',
    'CREATE INDEX IF NOT EXISTS idx_audit_problem    ON audit_trail(problem_id);',
    'CREATE INDEX IF NOT EXISTS idx_audit_created    ON audit_trail(created_at);',
    'CREATE INDEX IF NOT EXISTS idx_kb_category      ON knowledge_base(category);',
  ];

  /// داده‌های اولیه (کاربر پیش‌فرض = سازنده و مالک نرم‌افزار)
  static const List<String> seedStatements = [
    '''
    INSERT OR IGNORE INTO users (id, username, full_name, role)
    VALUES (1, 'hossein.bakhtiari', 'حسین بختیاری', 'admin');
    ''',
    "INSERT OR IGNORE INTO app_settings (key, value) VALUES ('app_version', '0.1.0');",
    "INSERT OR IGNORE INTO app_settings (key, value) VALUES ('default_locale', 'fa');",
  ];
}
