# repo-query

Queries the DuckDB repo index with arbitrary SQL to answer questions about repository structure, modules, dependencies, and entrypoints.

## How it works

Reads from the DuckDB database created by `repo-index` and runs SQL queries against it. The agent uses this to answer architectural questions without scanning the filesystem each time.

## Prerequisites

The index must exist first. Bootstrap it manually:

```bash
cd /path/to/your/repo
~/.dotfiles/opencode/skills/repo-index/scripts/repo-index.py
```

## Usage

```bash
~/.dotfiles/opencode/skills/repo-query/scripts/repo-query.py "SELECT module, path FROM modules WHERE repo_id = 'myrepo'"
```

Requires `uv`.

## Available tables

| Table | Columns |
|-------|---------|
| `repositories` | repo_id, path, indexed_at |
| `files` | repo_id, path |
| `modules` | repo_id, module, path |
| `dependencies` | repo_id, source_module, dependency |
| `entrypoints` | repo_id, path |

The `repo_id` is the directory name of the repo root (e.g. if your repo is at `~/projects/myapp`, the repo_id is `myapp`).

## Example queries

```sql
-- List all modules
SELECT module, path FROM modules WHERE repo_id = 'myapp'

-- Find what a module imports
SELECT dependency FROM dependencies WHERE source_module = 'mymodule' AND repo_id = 'myapp'

-- List entrypoints
SELECT path FROM entrypoints WHERE repo_id = 'myapp'
```
