# repo-index

Scans the current repository and stores its structure (files, modules, dependencies, entrypoints) into a DuckDB database for fast querying via `repo-query`.

## How it works

1. Walks the repo tree (skipping `.git`, `node_modules`, `.venv`, `dist`, `build`, `__pycache__`)
2. Detects Python/JS/TS modules and parses their imports
3. Identifies entrypoints (main functions, FastAPI apps, Express listeners)
4. Writes everything to a DuckDB database at `$OPENCODE_CONFIG_DIR/sqlite/repos.duckdb`

The `repo_id` is the directory name of the repo root.

## Bootstrap (manual first run)

Run this once from the repo root to create the index without using agent tokens:

```bash
~/.dotfiles/opencode/skills/repo-index/scripts/repo-index.py
```

Requires `uv` to be installed. The script uses inline script dependencies so no virtualenv setup is needed.

To re-index after structural changes, run the same command again.

## Environment

| Variable | Default | Purpose |
|----------|---------|---------|
| `REPO_DB_DIR` | `$OPENCODE_CONFIG_DIR/sqlite` | Directory for the DuckDB file |
| `OPENCODE_CONFIG_DIR` | `~/.dotfiles/opencode` | Base config directory |
