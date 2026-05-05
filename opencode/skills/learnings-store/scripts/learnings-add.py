#!/usr/bin/env python3
# /// script
# requires-python = ">=3.10"
# ///
"""Add a learning to the database."""
import argparse
import json
import sqlite3
import sys
from datetime import datetime, timezone
from pathlib import Path

DB_PATH = Path.home() / "code/.agents/learnings.db"

VALID_CATEGORIES = [
    "navigation", "tool-usage", "codebase", "gotcha",
    "fixture", "selector", "debugging",
]


def main():
    parser = argparse.ArgumentParser(description="Add an agent learning")
    parser.add_argument("--category", required=True, choices=VALID_CATEGORIES)
    parser.add_argument("--summary", required=True, help="Short description (under 100 chars)")
    parser.add_argument("--detail", help="Longer explanation")
    parser.add_argument("--tags", help="Comma-separated tags")
    parser.add_argument("--plan_id", help="Associated plan ID")
    parser.add_argument("--agent", default="regression-writer", help="Agent name")
    args = parser.parse_args()

    if not DB_PATH.exists():
        print("Error: learnings database not found. Run learnings-init.py first.", file=sys.stderr)
        sys.exit(1)

    conn = sqlite3.connect(str(DB_PATH))
    conn.execute(
        "INSERT INTO learnings (created_at, category, summary, detail, tags, plan_id, agent) VALUES (?, ?, ?, ?, ?, ?, ?)",
        (
            datetime.now(timezone.utc).isoformat(),
            args.category,
            args.summary,
            args.detail,
            args.tags,
            args.plan_id,
            args.agent,
        ),
    )
    conn.commit()
    row_id = conn.execute("SELECT last_insert_rowid()").fetchone()[0]
    conn.close()
    print(json.dumps({"ok": True, "id": row_id}))


if __name__ == "__main__":
    main()
