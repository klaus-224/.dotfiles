---
name: plan-store
description: Coordinate multi-agent planning through the SQLite plan store instead of transient markdown files
compatibility: opencode
metadata:
  workflow: planning
  audience: agents
---

## What I do

Use the `plan_*` custom tools as the source of truth for planning state.

The database is canonical.
Markdown is only a rendered view.

Map the planner/reviewer/executor roles onto specialized agents such as `code-planner`, `code-plan-reviewer`, and `code-implementer`.

## Rules

- Never treat a markdown plan file as canonical state.
- Before revising a plan, claim a lease.
- Revisions are append-only. Always create a new version.
- Reviewer feedback should be stored with `plan_comment`.
- Use `plan_transition` to move ownership between your planning, review, and execution agents.
- Only mark a plan approved once it has:
  - clear acceptance criteria
  - validation steps
  - any meaningful risks
  - touched files or affected areas
- Render markdown only for a disposable handoff or when the user explicitly asks for a readable file.

## Preferred workflow

### Planner

1. Look up an existing plan with `plan_list` or `plan_get`.
2. If needed, create a new plan with `plan_create`.
3. Claim the plan with `plan_claim`.
4. Revise canonical JSON with `plan_revise`.
5. Transition to `reviewing` and set `owner_agent` to your review agent, for example `code-plan-reviewer`.

### Reviewer

1. Read the latest version with `plan_get`.
2. Add comments with `plan_comment`.
3. If changes are needed, transition back to `drafting` and set `owner_agent` to your planning agent, for example `code-planner`.
4. If the plan is good, approve the target version with `plan_approve`.

### Executor

1. Read the approved version with `plan_get --approved`.
2. Optionally render markdown for a temporary handoff with `plan_render`.
3. Execute only from the approved version, not from stale prior drafts.
4. Once execution starts, transition to `executing`.
5. When done, transition to `done`.

## Canonical JSON checklist

Ensure the JSON includes these top-level fields where possible:

- `goal`
- `assumptions`
- `steps`
- `acceptance_criteria`
- `validation`
- `touched_files`
- `risks`
- `execution_notes`
