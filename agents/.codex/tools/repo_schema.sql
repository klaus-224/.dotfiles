CREATE TABLE IF NOT EXISTS repositories (
    repo_id TEXT PRIMARY KEY,
    path TEXT,
    indexed_at TIMESTAMP
);

CREATE TABLE IF NOT EXISTS files (
    repo_id TEXT,
    path TEXT
);

CREATE TABLE IF NOT EXISTS modules (
    repo_id TEXT,
    module TEXT,
    path TEXT
);

CREATE TABLE IF NOT EXISTS dependencies (
    repo_id TEXT,
    source_module TEXT,
    dependency TEXT
);

CREATE TABLE IF NOT EXISTS entrypoints (
    repo_id TEXT,
    path TEXT
);
