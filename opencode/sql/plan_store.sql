-- Source of truth for plan_store schema
PRAGMA journal_mode=WAL;
PRAGMA foreign_keys=ON;

CREATE TABLE IF NOT EXISTS plans (
  id TEXT PRIMARY KEY,
  task_key TEXT NOT NULL,
  title TEXT NOT NULL,
  state TEXT NOT NULL CHECK (state IN ('drafting', 'reviewing', 'approved', 'executing', 'done', 'abandoned')),
  owner_agent TEXT,
  current_version INTEGER,
  approved_version INTEGER,
  lease_owner TEXT,
  lease_expires_at TEXT,
  final_markdown_path TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_plans_task_key ON plans(task_key);
CREATE INDEX IF NOT EXISTS idx_plans_state ON plans(state);

CREATE TABLE IF NOT EXISTS plan_versions (
  plan_id TEXT NOT NULL,
  version INTEGER NOT NULL,
  created_by TEXT NOT NULL,
  created_at TEXT NOT NULL,
  parent_version INTEGER,
  change_note TEXT,
  plan_json TEXT NOT NULL,
  plan_summary TEXT,
  plan_gzip BLOB,
  PRIMARY KEY (plan_id, version),
  FOREIGN KEY (plan_id) REFERENCES plans(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS plan_events (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  plan_id TEXT NOT NULL,
  actor TEXT NOT NULL,
  event_type TEXT NOT NULL,
  payload_json TEXT,
  created_at TEXT NOT NULL,
  FOREIGN KEY (plan_id) REFERENCES plans(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS plan_comments (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  plan_id TEXT NOT NULL,
  version INTEGER NOT NULL,
  author_agent TEXT NOT NULL,
  comment_type TEXT NOT NULL CHECK (comment_type IN ('review', 'blocker', 'suggestion', 'note')),
  body TEXT NOT NULL,
  created_at TEXT NOT NULL,
  FOREIGN KEY (plan_id) REFERENCES plans(id) ON DELETE CASCADE,
  FOREIGN KEY (plan_id, version) REFERENCES plan_versions(plan_id, version) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_plan_versions_plan_id ON plan_versions(plan_id, version DESC);
CREATE INDEX IF NOT EXISTS idx_plan_comments_plan_id ON plan_comments(plan_id, version);
CREATE INDEX IF NOT EXISTS idx_plan_events_plan_id ON plan_events(plan_id, created_at);
