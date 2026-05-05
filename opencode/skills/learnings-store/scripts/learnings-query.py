#!/usr/bin/env python3
# /// script
# requires-python = ">=3.10"
# ///
"""Query the learnings database."""
import argparse
import json
import sqlite3
import sys
from pathlib import Path

DB_PATH = Path.home() / "code/.agents/learnings.db"


def main():
    parser = argparse.ArgumentParser(description="Query agent learnings")
    parser.add_argument("--category", help="Filter by category")
    parser.add_argument("--tags", help="Comma-separated tags to filter by (AND)")
    parser.add_argument("--search", help="Full-text search across summary and detail")
    parser.add_argument("--recent", type=int, help="Show N most recent learnings")
    parser.add_argument("--limit", type=int, default=20, help="Max results (default 20)")
    args = parser.parse_args()

    if not DB_PATH.exists():
        print("Error: learnings database not found. Run learnings-init.py first.", file=sys.stderr)
        sys.exit(1)

    conn = sqlite3.connect(str(DB_PATH))
    conn.row_factory = sqlite3.Row

    if args.recent:
        rows = conn.execute(
            "SELECT * FROM learnings ORDER BY created_at DESC LIMIT ?",
            (args.recent,),
        ).fetchall()
    else:
        conditions = []
        params = []

        if args.category:
            conditions.append("l.category = ?")
            params.append(args.category)

        if args.tags:
            for tag in args.tags.split(","):
                conditions.append("l.tags LIKE ?")
                params.append(f"%{tag.strip()}%")

        if args.search:
            fts_ids = conn.execute(
                "SELECT rowid FROM learnings_fts WHERE learnings_fts MATCH ?",
                (args.search,),
            ).fetchall()
            if not fts_ids:
                print(json.dumps([]))
                conn.close()
                return
            id_list = ",".join(str(r[0]) for r in fts_ids)
            conditions.append(f"l.id IN ({id_list})")

        where = "WHERE " + " AND ".join(conditions) if conditions else ""
        rows = conn.execute(
            f"SELECT * FROM learnings l {where} ORDER BY l.created_at DESC LIMIT ?",
            params + [args.limit],
        ).fetchall()

    conn.close()

    results = [dict(r) for r in rows]
    if not results:
        print("No learnings found.")
    else:
        print(json.dumps(results, indent=2))


if __name__ == "__main__":
    main()
