-- Source of truth for learnings_store schema
PRAGMA journal_mode=WAL;

CREATE TABLE IF NOT EXISTS learnings (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ', 'now')),
  category TEXT NOT NULL CHECK (category IN (
    'navigation', 'tool-usage', 'codebase', 'gotcha',
    'fixture', 'selector', 'debugging'
  )),
  summary TEXT NOT NULL,
  detail TEXT,
  tags TEXT,
  plan_id TEXT,
  agent TEXT
);

CREATE INDEX IF NOT EXISTS idx_learnings_category ON learnings(category);
CREATE INDEX IF NOT EXISTS idx_learnings_tags ON learnings(tags);

CREATE VIRTUAL TABLE IF NOT EXISTS learnings_fts USING fts5(
  summary, detail, content=learnings, content_rowid=id
);

CREATE TRIGGER IF NOT EXISTS learnings_ai AFTER INSERT ON learnings BEGIN
  INSERT INTO learnings_fts(rowid, summary, detail) VALUES (new.id, new.summary, new.detail);
END;
