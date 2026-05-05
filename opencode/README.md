# OpenCode Configuration

Personal OpenCode configuration managed via dotfiles.

## Structure

```
~/.dotfiles/opencode/
├── AGENTS.md              # Global operating rules for all agents
├── opencode.work.jsonc    # Work profile config
├── opencode.personal.jsonc
├── tools/                 # Custom tools (TypeScript, @opencode-ai/plugin)
├── agents/                # Subagent definitions
├── skills/                # Skill files (loaded on demand)
├── commands/              # Slash commands
├── bin/                   # Standalone scripts (on PATH)
├── sql/                   # SQL snippets
└── tui.json               # TUI theme
```

## Tools

Custom tools registered via `"tools": { "paths": true }` in config. The agent sees these in its tool list automatically.

| File            | Tool(s)                                                                                                                                                            | Description                                                          |
| --------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------ | -------------------------------------------------------------------- |
| `tools/repo.ts` | `repo_index`, `repo_query`                                                                                                                                         | Index repo structure + data-testids into DuckDB, then query with SQL |
| `tools/auth.ts` | `auth`                                                                                                                                                             | Authenticate to Skyon (runs Playwright setup spec with secrets)      |
| `tools/plan.ts` | `plan_init`, `plan_create`, `plan_claim`, `plan_release`, `plan_revise`, `plan_approve`, `plan_transition`, `plan_comment`, `plan_get`, `plan_list`, `plan_render` | Multi-agent plan store (SQLite-backed)                               |

### repo_index

Indexes the current repo into `~/.codex/sqlite/repos.duckdb`. Scans files, modules, imports, entrypoints, and `data-testid` attributes.

```
# Agent just calls the tool — no arguments needed
repo_index
```

### repo_query

Runs SQL against the indexed DuckDB. Useful tables:

| Table          | Columns                                             |
| -------------- | --------------------------------------------------- |
| `files`        | repo_id, path                                       |
| `modules`      | repo_id, module, path                               |
| `dependencies` | repo_id, source_module, dependency                  |
| `entrypoints`  | repo_id, path                                       |
| `testids`      | repo_id, testid, component, filepath, line, context |

```sql
-- Find all data-testids for a component
SELECT testid, component, filepath, line
FROM testids
WHERE repo_id = 'skyon-worktree' AND component LIKE '%Button%';

-- Find all entrypoints
SELECT path FROM entrypoints WHERE repo_id = 'skyon-worktree';

-- List modules that depend on a specific package
SELECT source_module, dependency
FROM dependencies
WHERE repo_id = 'skyon-worktree' AND dependency LIKE '%zod%';
```

### auth

Authenticates to the Skyon app for Playwright tests. Uses `secrets` CLI to inject credentials.

```
# Agent calls with literal env var names (secrets are injected at runtime)
auth(username: "SKYON_USERNAME", password: "SKYON_PASSWORD")
```

## Agents

| Agent             | Mode     | Model             | Purpose                                                                             |
| ----------------- | -------- | ----------------- | ----------------------------------------------------------------------------------- |
| `test-planner`    | subagent | claude-opus-4.6   | Gathers Jira context + code changes, produces a manual test plan in the plan store  |
| `test-executor`   | subagent | gpt-5.4           | Executes an approved test plan via Playwright CLI, posts results to Jira            |
| `pair-programmer` | primary  | claude-sonnet-4.6 | Read-only pair programming — reviews code, suggests changes, chats through problems |

## Skills

Loaded on demand when the agent recognizes a matching task.

| Skill            | Description                                                    |
| ---------------- | -------------------------------------------------------------- |
| `plan-store`     | Instructions for using `plan_*` tools for multi-agent planning |
| `playwright-cli` | Browser automation via `playwright-cli` CLI                    |
| `repo-index`     | Documents what `repo_index` indexes and how                    |
| `repo-map`       | Generates repo structure as JSON + Graphviz dependency graph   |
| `repo-query`     | Documents how to query the DuckDB index                        |

## Commands (Slash Commands)

| Command                                   | Description                                             |
| ----------------------------------------- | ------------------------------------------------------- |
| `/manual-test-all <BASE_URL>`             | Run manual testing for all Jira tickets assigned to you |
| `/manual-test-single <TICKET> <BASE_URL>` | Run manual testing for one Jira ticket                  |

## Bin Scripts

Scripts in `~/.dotfiles/opencode/bin/` (on PATH):

| Script          | Description                                                     |
| --------------- | --------------------------------------------------------------- |
| `plan_store.py` | CLI for the plan store (used by `tools/plan.ts` under the hood) |

## MCP Servers

| Server      | Type   | Description                               |
| ----------- | ------ | ----------------------------------------- |
| `atlassian` | remote | Jira + Confluence via `mcp.atlassian.com` |
