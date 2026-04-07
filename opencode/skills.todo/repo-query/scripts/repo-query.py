#!/usr/bin/env -S uv run --script
# /// script
# dependencies = ["duckdb"]
# ///

import os
import pathlib
import sys

import duckdb


DEFAULT_DB_DIR = pathlib.Path.home() / ".codex/sqlite"


def main() -> int:
    if len(sys.argv) != 2:
        print(f"Usage: {pathlib.Path(sys.argv[0]).name} \"<SQL>\"", file=sys.stderr)
        return 1

    sql = sys.argv[1]

    db_dir = pathlib.Path(
        os.environ.get("CODEX_REPO_DB_DIR", str(DEFAULT_DB_DIR))
    ).expanduser()
    db_path = db_dir / "repos.duckdb"

    if not db_path.exists():
        print(
            f"Database not found: {db_path}",
            file=sys.stderr,
        )
        return 1

    con = duckdb.connect(str(db_path), read_only=True)
    try:
        rows = con.execute(sql).fetchall()
        for row in rows:
            print("\t".join("" if value is None else str(value) for value in row))
    finally:
        con.close()

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
