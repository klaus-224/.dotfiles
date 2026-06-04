-- Source of truth for agent_memory schema
PRAGMA journal_mode=WAL;

CREATE TABLE IF NOT EXISTS agent_memory (
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

CREATE INDEX IF NOT EXISTS idx_agent_memory_category ON agent_memory(category);
CREATE INDEX IF NOT EXISTS idx_agent_memory_tags ON agent_memory(tags);

CREATE VIRTUAL TABLE IF NOT EXISTS agent_memory_fts USING fts5(
  summary, detail, content=agent_memory, content_rowid=id
);

CREATE TRIGGER IF NOT EXISTS agent_memory_ai AFTER INSERT ON agent_memory BEGIN
  INSERT INTO agent_memory_fts(rowid, summary, detail) VALUES (new.id, new.summary, new.detail);
END;
