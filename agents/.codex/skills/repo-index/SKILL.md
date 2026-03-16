---
name: repo-index
description: >
  Indexes the current repository's files, modules, dependencies, and entrypoints
  into a DuckDB database. Use when asked to index, scan, or catalog a repo, or
  before using $repo-query for the first time.
---

# Repo Index

Scans the current repository and stores its structure in a DuckDB database for
fast querying with `$repo-query`.

## When to use

- Before using `$repo-query` for the first time in a repository
- When the repository structure has changed and needs re-indexing
- When asked to "index", "scan", or "catalog" the repo

## How to run

Execute from the repository root:

```bash
$HOME/.codex/skills/repo-index/scripts/repo-index.py
```

Requires `uv` (the script uses inline script dependencies).

## What it indexes

- All files (excluding .git, node_modules, .venv, dist, build, **pycache**)
- Python/JS/TS modules and their import dependencies
- Entrypoints (main functions, FastAPI apps, Express listeners)

## Output

Writes to `~/.codex/sqlite/repos.duckdb`. The `repo_id` is the directory name
of the repository root.
