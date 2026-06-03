# Repo Tool

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
