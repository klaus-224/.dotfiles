#!/usr/bin/env -S uv run --script
# /// script
# dependencies = ["duckdb"]
# ///
import os
import pathlib
import re
import time

import duckdb

ROOT = pathlib.Path(".").resolve()
REPO_ID = ROOT.name

DB_DIR = pathlib.Path.home() / ".codex/sqlite"


def resolve_db_dir() -> pathlib.Path:
    configured = pathlib.Path(os.environ.get("REPO_DB_DIR", str(DB_DIR))).expanduser()
    configured.mkdir(parents=True, exist_ok=True)
    return configured


IGNORE_DIRS = {".git", "node_modules", ".venv", "dist", "build", "__pycache__", "playwright-tests"}

IMPORT_PATTERNS = [
    r"import ([a-zA-Z0-9_\.]+)",
    r"from ([a-zA-Z0-9_\.]+) import",
    r"require\(['\"](.*?)['\"]\)",
    r"import .* from ['\"](.*?)['\"]",
]

ENTRYPOINT_PATTERNS = [
    r"if __name__ == ['\"]__main__['\"]",
    r"app\.listen",
    r"FastAPI\(",
    r"main\(",
]


def is_ignored(p):
    return any(part in IGNORE_DIRS for part in p.parts)


def collect_files():
    for p in ROOT.rglob("*"):
        if p.is_file() and not is_ignored(p):
            yield p


def ensure_schema(con):

    con.execute("""
    CREATE TABLE IF NOT EXISTS repositories (
        repo_id TEXT,
        path TEXT,
        indexed_at INTEGER
    )
    """)

    con.execute("""
    CREATE TABLE IF NOT EXISTS files (
        repo_id TEXT,
        path TEXT
    )
    """)

    con.execute("""
    CREATE TABLE IF NOT EXISTS modules (
        repo_id TEXT,
        module TEXT,
        path TEXT
    )
    """)

    con.execute("""
    CREATE TABLE IF NOT EXISTS dependencies (
        repo_id TEXT,
        source_module TEXT,
        dependency TEXT
    )
    """)

    con.execute("""
    CREATE TABLE IF NOT EXISTS entrypoints (
        repo_id TEXT,
        path TEXT
    )
    """)

    con.execute("""
    CREATE TABLE IF NOT EXISTS testids (
        repo_id TEXT,
        testid TEXT,
        component TEXT,
        filepath TEXT,
        line INTEGER,
        context TEXT
    )
    """)


def index_repo():
    db_dir = resolve_db_dir()
    db_path = db_dir / "repos.duckdb"
    con = duckdb.connect(str(db_path))

    ensure_schema(con)

    # Clear previous index
    con.execute("DELETE FROM files WHERE repo_id=?", [REPO_ID])
    con.execute("DELETE FROM modules WHERE repo_id=?", [REPO_ID])
    con.execute("DELETE FROM dependencies WHERE repo_id=?", [REPO_ID])
    con.execute("DELETE FROM entrypoints WHERE repo_id=?", [REPO_ID])
    con.execute("DELETE FROM testids WHERE repo_id=?", [REPO_ID])

    con.execute(
        "INSERT INTO repositories VALUES (?, ?, ?)",
        [REPO_ID, str(ROOT), int(time.time())],
    )

    for f in collect_files():
        con.execute("INSERT INTO files VALUES (?, ?)", [REPO_ID, str(f)])

        if f.suffix not in {".py", ".ts", ".js"}:
            continue

        module = f.stem

        con.execute("INSERT INTO modules VALUES (?, ?, ?)", [REPO_ID, module, str(f)])

        try:
            text = f.read_text(errors="ignore")
        except OSError:
            continue

        for pattern in IMPORT_PATTERNS:
            matches = re.findall(pattern, text)

            for m in matches:
                con.execute(
                    "INSERT INTO dependencies VALUES (?, ?, ?)", [REPO_ID, module, m]
                )

        for pattern in ENTRYPOINT_PATTERNS:
            if re.search(pattern, text):
                con.execute("INSERT INTO entrypoints VALUES (?, ?)", [REPO_ID, str(f)])

    # Scan for data-testids
    scan_testids(con)

    con.close()

    print(f"Indexed repo '{REPO_ID}' into {db_path} (duckdb)")


TESTID_EXTENSIONS = {".svelte", ".tsx", ".ts", ".jsx", ".js", ".html"}
TESTID_RE = re.compile(r'data-testid=["\']([^"\']+)["\']')


def kebab_to_pascal(name: str) -> str:
    return "".join(word.capitalize() for word in name.replace("_", "-").split("-"))


def scan_testids(con):
    for f in collect_files():
        if f.suffix not in TESTID_EXTENSIONS:
            continue
        try:
            lines = f.read_text(errors="ignore").splitlines()
        except OSError:
            continue
        component = kebab_to_pascal(f.stem)
        rel_path = str(f.relative_to(ROOT))
        for i, line in enumerate(lines, 1):
            for m in TESTID_RE.finditer(line):
                con.execute(
                    "INSERT INTO testids VALUES (?, ?, ?, ?, ?, ?)",
                    [REPO_ID, m.group(1), component, rel_path, i, line.strip()],
                )


if __name__ == "__main__":
    index_repo()
