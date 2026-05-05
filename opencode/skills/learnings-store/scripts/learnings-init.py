#!/usr/bin/env python3
# /// script
# requires-python = ">=3.10"
# ///
"""Initialize the learnings SQLite database."""
import sqlite3
import sys
from pathlib import Path

DB_PATH = Path.home() / "code/.agents/learnings.db"

SCHEMA = """
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
"""


def main():
    DB_PATH.parent.mkdir(parents=True, exist_ok=True)
    conn = sqlite3.connect(str(DB_PATH))
    conn.executescript(SCHEMA)
    conn.close()
    print(f"Learnings database initialized at {DB_PATH}")


if __name__ == "__main__":
    main()
