---
name: learnings-store
description: >
  Query and record agent learnings about the codebase, navigation, tools, and
  debugging. Used by regression test agents to accumulate knowledge across runs.
---

# Learnings Store

A SQLite database of observations accumulated by agents across regression test runs. Agents query it at the start of a run to avoid repeating mistakes and record new discoveries at the end.

## When to use

- At the start of any regression planning or writing task — query for relevant prior knowledge
- At the end of a regression writing run — record what was learned (writer only)
- When an agent gets stuck — query for debugging tips and gotchas

## Scripts

### Initialize the database

```bash
python3 $OPENCODE_CONFIG_DIR/skills/learnings-store/scripts/learnings-init.py
```

Run once. Safe to re-run (idempotent).

### Query learnings

```bash
python3 $OPENCODE_CONFIG_DIR/skills/learnings-store/scripts/learnings-query.py --search "source panel"
python3 $OPENCODE_CONFIG_DIR/skills/learnings-store/scripts/learnings-query.py --category gotcha
python3 $OPENCODE_CONFIG_DIR/skills/learnings-store/scripts/learnings-query.py --category navigation --tags "map,filter"
python3 $OPENCODE_CONFIG_DIR/skills/learnings-store/scripts/learnings-query.py --recent 5
```

### Add a learning (writer agent only)

```bash
python3 $OPENCODE_CONFIG_DIR/skills/learnings-store/scripts/learnings-add.py \
  --category gotcha \
  --summary "Dashboard fixture closes AI agent popup but it reappears after navigation" \
  --detail "Use dashboard.closeAiAgent() again after any page navigation." \
  --tags "ai-agent,navigation" \
  --plan_id "plan-abc123"
```

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
- Keep summaries under 100 characters. Put details in `--detail`.
- Tag generously — tags enable cross-cutting queries.
- Always include `--plan_id` when available for traceability.

## Database location

`~/code/.agents/learnings.db`
