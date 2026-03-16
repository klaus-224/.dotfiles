---
name: repo-query
description: >
  Queries the DuckDB repo index with SQL to answer questions about repository
  structure, modules, dependencies, and entrypoints. Run $repo-index first if
  the index does not exist.
---

# Repo Query

Query the indexed repository database with arbitrary SQL.

## When to use

- When asked about repo structure, dependencies, modules, or entrypoints
- To find relationships between modules
- To answer architectural questions about an indexed codebase

## How to run

```bash
$HOME/.codex/skills/repo-query/scripts/repo-query.py "<SQL>"
```

Requires `uv` and a pre-existing index (run `$repo-index` first).

## Available tables

| Table        | Columns                            |
| ------------ | ---------------------------------- |
| repositories | repo_id, path, indexed_at          |
| files        | repo_id, path                      |
| modules      | repo_id, module, path              |
| dependencies | repo_id, source_module, dependency |
| entrypoints  | repo_id, path                      |

See `references/repo_schema.sql` for the full schema.

## Example queries

```sql
-- List all modules
SELECT module, path FROM modules WHERE repo_id = '<repo-name>'

-- Find what a module imports
SELECT dependency FROM dependencies
WHERE source_module = '<module>' AND repo_id = '<repo-name>'

-- List entrypoints
SELECT path FROM entrypoints WHERE repo_id = '<repo-name>'
```

The `repo_id` is the directory name of the repository root.
