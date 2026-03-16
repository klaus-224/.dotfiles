#!/usr/bin/env -S uv run --script
# /// script
# dependencies = ["duckdb"]
# ///

import pathlib
import sys

import duckdb


DB = pathlib.Path.home() / ".codex/sqlite/repos.duckdb"


def main() -> int:
    if len(sys.argv) != 2:
        print(f"Usage: {pathlib.Path(sys.argv[0]).name} \"<SQL>\"", file=sys.stderr)
        return 1

    sql = sys.argv[1]

    if not DB.exists():
        print(f"Database not found: {DB}", file=sys.stderr)
        return 1

    con = duckdb.connect(str(DB), read_only=True)
    try:
        rows = con.execute(sql).fetchall()
        for row in rows:
            print("\t".join("" if value is None else str(value) for value in row))
    finally:
        con.close()

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
