# Tools

## Repo Tool

Unified repo tool for indexing, querying, mapping, and searching repositories using DuckDB.

## Usage

```bash
repo index              # Index the current repo
repo query "SELECT ..." # Query the index with SQL
repo map                # Generate repo map (JSON + Graphviz)
repo search "query"     # Full-text search across indexed chunks
```

## Architecture

- **`bin/repo-rs`** — Rust script (via `rust-script`) that handles all CLI commands
- **`opencode/sql/repo_index.sql`** — Schema definition (DuckDB dialect)
- **`opencode/tools/repo.ts`** — OpenCode plugin exposing `index`, `query`, and `search` tools

## Tables

| Table | Purpose |
|-------|---------|
| `repositories` | Indexed repo metadata |
| `files` | All file paths in the repo |
| `modules` | Python/TS/JS modules |
| `dependencies` | Import relationships |
| `entrypoints` | Main/entry files |
| `testids` | data-testid attributes |
| `file_chunks` | Chunked file content with FTS |

## Search

The `search` command uses DuckDB's FTS extension with BM25 scoring. Each file is split into chunks (~80 lines for code, heading-based for markdown) with:
- `search_text`: combined path tokens + title + description + content
- `description`: deterministic natural-language summary
- `path_text`: search-friendly path (slashes/dots → spaces)

Query preprocessing strips stop words to handle natural-language queries from agents.

## V2 Roadmap: Symbol Table

After chunk FTS is proven useful, add structured AST-based symbol extraction:

```sql
CREATE TABLE IF NOT EXISTS symbols (
  symbol_id TEXT,       -- "{repo_id}::{filepath}::{name}"
  repo_id TEXT,
  name TEXT,
  kind TEXT,            -- function | method | class | constant | variable | type
  language TEXT,
  filepath TEXT,
  line_start INTEGER,
  line_end INTEGER,
  signature TEXT,
  description TEXT
);
```

### Language support plan
- **Python** — `tree-sitter` or Python `ast` module
- **TypeScript/JavaScript** — `tree-sitter`
- **Lua** — `tree-sitter` (lua grammar)
- **Rust** — `tree-sitter` or `syn` for native parsing
- **Zsh/Shell** — regex-based extraction (function declarations, aliases)

### Future additions (after symbols prove useful)
- `references` field (JSON array of symbol_ids this symbol calls/uses)
- Caller/callee graph queries
- LLM-generated descriptions
- Vector embeddings / hybrid search

## Memory Tool

Learnings store for navigation, tool usage, codebase notes, gotchas, fixtures, selectors, and debugging.

### Architecture

- **`bin/agent_memory`** — Python CLI for `init`, `query`, and `add`
- **`opencode/sql/agent_memory.sql`** — SQLite schema definition
- **`opencode/tools/memory.ts`** — OpenCode plugin exposing the memory tools

### Env Vars
`AGENT_MEMORY_DB_PATH` - defaults to `~/.local/state/agent-tools/memory.db`
`AGENT_MEMORY_SCHEMA_PATH` - defaults to `$TOOL_DIR/opencode/sql/agent_memory.sql`

### Exposed Tools

- **`memory_init`** — initialize the SQLite database
- **`memory_query`** — query stored learnings
- **`memory_add`** — add a new learning

### Migration Command
``` zsh
sqlite3 <PATH_TO_CURRENT_DB_FILE> < <PATH_TO_MIGRATION_FILE>
```

### Usage

Use structured arguments for tool calls:

```ts
memory.query({ search: "ION-9664 export table", limit: 20 })
memory.query({ category: "navigation", recent: 5 })
memory.add({ category: "codebase", summary: "Export uses agent_memory FTS", tags: "ion,export" })
```

Do not pass search terms positionally. Always use the named `search` argument.

Use `MEMORY_SCHEMA_PATH` to override the schema file path for `bin/agent_memory`.
