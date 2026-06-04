-- Source of truth for repo index schema (DuckDB dialect)
CREATE TABLE IF NOT EXISTS repositories (repo_id TEXT, path TEXT, indexed_at INTEGER);

CREATE TABLE IF NOT EXISTS files (repo_id TEXT, path TEXT);

CREATE TABLE IF NOT EXISTS modules (repo_id TEXT, module TEXT, path TEXT);

CREATE TABLE IF NOT EXISTS dependencies (
    repo_id TEXT,
    source_module TEXT,
    dependency TEXT
);

CREATE TABLE IF NOT EXISTS entrypoints (repo_id TEXT, path TEXT);

CREATE TABLE IF NOT EXISTS testids (
    repo_id TEXT,
    testid TEXT,
    component TEXT,
    filepath TEXT,
    line INTEGER,
    context TEXT
);

CREATE TABLE IF NOT EXISTS file_chunks (
    chunk_id TEXT,
    repo_id TEXT,
    path TEXT,
    path_text TEXT,
    language TEXT,
    chunk_kind TEXT,
    chunk_start INTEGER,
    chunk_end INTEGER,
    title TEXT,
    description TEXT,
    content TEXT,
    search_text TEXT
);
