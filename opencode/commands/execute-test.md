---
description: Execute one stored manual test plan via Playwright CLI
agent: test-executor
---

## Input

- `plan_id` is required

## Task

Execute the stored plan using Playwright CLI against the stored base URL.

Stay close to the stored plan.
Only branch into adjacent checks when needed to confirm a likely regression or blocker.

## Output

Write execution results to the plan store via `plan_revise`:

- commands_run
- passed
- failed
- blocked
- not_tested
- evidence
- follow_up
- final_status

## Auth

- Use auth state at `apps/playwright-tests/.auth/dev.json`
- Never run login or auth refresh
- Never print or expose `.auth/` contents
- If auth is missing or invalid, return `auth-blocked`

## Artifacts

- Store artifacts under `$(dirname "$OPENCODE_PLAN_DB")/<plan_id>/`
- Never write artifacts into the repo

## Rules

- Require `plan_id`.
- Write all results to the plan store.
- Stop and surface blockers instead of guessing.
- Do not modify Jira.
- Do not modify the plan except through execution results.

Context: $ARGUMENTS
