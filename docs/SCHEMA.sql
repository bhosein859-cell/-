-- ═══════════════════════════════════════════════════════════════════
--  گره‌گشا (Gereh-Gosha) — اسکیمای دیتابیس نسخه‌ی ۱ (فاز صفر)
--  طراح و مالک: حسین بختیاری
--  توضیح: این فایل معادل مستقلِ اسکیمای پیاده‌شده در
--  lib/data/database/schema.dart است و برای مرور معماری ارائه می‌شود.
-- ═══════════════════════════════════════════════════════════════════

PRAGMA foreign_keys = ON;

-- ─────────────────────────── کاربران ───────────────────────────
CREATE TABLE IF NOT EXISTS users (
  id            INTEGER PRIMARY KEY AUTOINCREMENT,
  username      TEXT    NOT NULL UNIQUE,
  full_name     TEXT    NOT NULL,
  role          TEXT    NOT NULL DEFAULT 'member',   -- admin | manager | member
  avatar_path   TEXT,                                -- تصویر پروفایل
  password_hash TEXT,                                -- هش رمز عبور محلی
  salt          TEXT,
  is_active     INTEGER NOT NULL DEFAULT 1,
  created_at    TEXT    NOT NULL DEFAULT (datetime('now')),
  updated_at    TEXT,
  metadata      TEXT    NOT NULL DEFAULT '{}'        -- JSON برای ویژگی‌های آینده
);

-- ─────────────────────────── مسائل ─────────────────────────────
CREATE TABLE IF NOT EXISTS problems (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  code        TEXT    UNIQUE,                        -- PRB-0001
  title       TEXT    NOT NULL,
  description TEXT,
  level       INTEGER NOT NULL CHECK (level IN (1, 2, 3)),
  status      TEXT    NOT NULL DEFAULT 'open',       -- open|in_progress|resolved|closed
  priority    TEXT    NOT NULL DEFAULT 'medium',     -- low|medium|high|critical
  owner_id    INTEGER REFERENCES users(id) ON DELETE SET NULL,
  created_by  INTEGER REFERENCES users(id) ON DELETE SET NULL,
  methodology TEXT,                                  -- PDCA|8D|DMAIC|...
  due_date    TEXT,
  resolved_at TEXT,
  created_at  TEXT    NOT NULL DEFAULT (datetime('now')),
  updated_at  TEXT,
  metadata    TEXT    NOT NULL DEFAULT '{}'
);

-- ─────────────────────────── اقدامات ───────────────────────────
CREATE TABLE IF NOT EXISTS actions (
  id           INTEGER PRIMARY KEY AUTOINCREMENT,
  problem_id   INTEGER NOT NULL REFERENCES problems(id) ON DELETE CASCADE,
  title        TEXT    NOT NULL,
  description  TEXT,
  phase        TEXT,                                 -- Plan|Do|Check|Act
  assignee_id  INTEGER REFERENCES users(id) ON DELETE SET NULL,
  status       TEXT    NOT NULL DEFAULT 'pending',   -- pending|in_progress|done|blocked
  progress     INTEGER NOT NULL DEFAULT 0 CHECK (progress BETWEEN 0 AND 100),
  due_date     TEXT,
  completed_at TEXT,
  created_at   TEXT    NOT NULL DEFAULT (datetime('now')),
  metadata     TEXT    NOT NULL DEFAULT '{}'
);

-- ─────────────────────────── پیوست‌ها ──────────────────────────
CREATE TABLE IF NOT EXISTS attachments (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  problem_id  INTEGER NOT NULL REFERENCES problems(id) ON DELETE CASCADE,
  file_name   TEXT    NOT NULL,
  file_path   TEXT    NOT NULL,                      -- مسیر نسبی در پوشه‌ی attachments
  mime_type   TEXT,
  size_bytes  INTEGER,
  uploaded_by INTEGER REFERENCES users(id) ON DELETE SET NULL,
  created_at  TEXT    NOT NULL DEFAULT (datetime('now')),
  metadata    TEXT    NOT NULL DEFAULT '{}'
);

-- ──────────────────── تاریخچه‌ی تغییرات ────────────────────────
CREATE TABLE IF NOT EXISTS audit_trail (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  problem_id  INTEGER REFERENCES problems(id) ON DELETE CASCADE,
  user_id     INTEGER REFERENCES users(id) ON DELETE SET NULL,
  action      TEXT    NOT NULL,                      -- create|update|delete|export_psp|import_psp|...
  entity_type TEXT,
  entity_id   INTEGER,
  details     TEXT,                                  -- JSON
  created_at  TEXT    NOT NULL DEFAULT (datetime('now'))
);

-- ─────────────────────────── بانک دانش ─────────────────────────
CREATE TABLE IF NOT EXISTS knowledge_base (
  id         INTEGER PRIMARY KEY AUTOINCREMENT,
  problem_id INTEGER REFERENCES problems(id) ON DELETE SET NULL,
  title      TEXT    NOT NULL,
  summary    TEXT,                                   -- خلاصه‌ی راه‌حل
  solution   TEXT,
  tags       TEXT    NOT NULL DEFAULT '[]',          -- آرایه‌ی JSON
  category   TEXT,
  author_id  INTEGER REFERENCES users(id) ON DELETE SET NULL,
  created_at TEXT    NOT NULL DEFAULT (datetime('now')),
  metadata   TEXT    NOT NULL DEFAULT '{}'
);

-- ──────────────── جدول‌های زیرساختی/آینده ─────────────────────
CREATE TABLE IF NOT EXISTS app_settings (
  key        TEXT PRIMARY KEY,
  value      TEXT,
  updated_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS feature_flags (
  feature_key TEXT PRIMARY KEY,
  name_fa     TEXT,
  enabled     INTEGER NOT NULL DEFAULT 0
);

-- ─────────────────────────── ایندکس‌ها ─────────────────────────
CREATE INDEX IF NOT EXISTS idx_problems_status ON problems(status);
CREATE INDEX IF NOT EXISTS idx_problems_level  ON problems(level);
CREATE INDEX IF NOT EXISTS idx_problems_owner  ON problems(owner_id);
CREATE INDEX IF NOT EXISTS idx_actions_problem ON actions(problem_id);
CREATE INDEX IF NOT EXISTS idx_actions_status  ON actions(status);
CREATE INDEX IF NOT EXISTS idx_attach_problem  ON attachments(problem_id);
CREATE INDEX IF NOT EXISTS idx_audit_problem   ON audit_trail(problem_id);
CREATE INDEX IF NOT EXISTS idx_audit_created   ON audit_trail(created_at);
CREATE INDEX IF NOT EXISTS idx_kb_category     ON knowledge_base(category);

-- ─────────────────────────── داده‌ی اولیه ───────────────────────
INSERT OR IGNORE INTO users (id, username, full_name, role)
VALUES (1, 'hossein.bakhtiari', 'حسین بختیاری', 'admin');

INSERT OR IGNORE INTO app_settings (key, value) VALUES ('app_version', '0.1.0');
INSERT OR IGNORE INTO app_settings (key, value) VALUES ('default_locale', 'fa');
