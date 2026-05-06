---
name: learnings-store
description: >
  Query and record agent learnings about the codebase, navigation, tools, and
  debugging. Used by regression test agents to accumulate knowledge across runs.
---

# Learnings Store

Use the `learnings_query` and `learnings_add` tools to interact with the learnings database.

## When to use

- At the start of any regression planning or writing task — query for relevant prior knowledge
- At the end of a regression writing run — record what was learned (writer only)
- When an agent gets stuck — query for debugging tips and gotchas

## Categories

| Category | What goes here |
|----------|---------------|
| `navigation` | How to reach specific pages/states, workarounds for nav issues |
| `tool-usage` | When to use playwright-cli vs repo-query, why one tool was better |
| `codebase` | Structural knowledge — where things live, naming conventions |
| `gotcha` | Timing issues, race conditions, flaky selectors, surprises |
| `fixture` | Notes on existing fixtures — capabilities, limitations |
| `selector` | Which selectors work reliably, data-testid coverage gaps |
| `debugging` | How to get unstuck — common failures and solutions |

## Rules

- Only the `regression-writer` agent adds learnings (it has implementation experience).
- All agents may query learnings.
- Keep summaries under 100 characters. Put details in `detail`.
- Tag generously — tags enable cross-cutting queries.
- Always include `plan_id` when available for traceability.

## CLI usage

```bash
python3 ~/.dotfiles/opencode/bin/learnings_store.py init
python3 ~/.dotfiles/opencode/bin/learnings_store.py query --search "source panel"
python3 ~/.dotfiles/opencode/bin/learnings_store.py query --category gotcha --tags "ai-agent"
python3 ~/.dotfiles/opencode/bin/learnings_store.py query --recent 5
python3 ~/.dotfiles/opencode/bin/learnings_store.py add --category gotcha --summary "..." --detail "..." --tags "x,y"
```

## Database location

`~/code/.agents/learnings.db`
