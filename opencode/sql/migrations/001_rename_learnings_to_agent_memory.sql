-- Migration: rename learnings -> agent_memory
-- Intended to be run manually against an existing learnings.db.

DROP TRIGGER IF EXISTS learnings_ai;
DROP TABLE IF EXISTS learnings_fts;

ALTER TABLE learnings RENAME TO agent_memory;

DROP INDEX IF EXISTS idx_learnings_category;
DROP INDEX IF EXISTS idx_learnings_tags;
CREATE INDEX IF NOT EXISTS idx_agent_memory_category ON agent_memory(category);
CREATE INDEX IF NOT EXISTS idx_agent_memory_tags ON agent_memory(tags);

CREATE VIRTUAL TABLE IF NOT EXISTS agent_memory_fts USING fts5(
  summary, detail, content=agent_memory, content_rowid=id
);

INSERT INTO agent_memory_fts(rowid, summary, detail)
SELECT id, summary, detail FROM agent_memory;

CREATE TRIGGER IF NOT EXISTS agent_memory_ai AFTER INSERT ON agent_memory BEGIN
  INSERT INTO agent_memory_fts(rowid, summary, detail) VALUES (new.id, new.summary, new.detail);
END;
