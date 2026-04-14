---
description: Execute a revised manual test plan via Playwright CLI
agent: manual-test-executor
---

## Input

- `plan_id` is required — the plan store contains the revised test plan

## Task

Execute the test plan using Playwright CLI:

- Follow the revised plan — stay close to it
- Only expand into adjacent checks when justified by high risk
- Capture evidence for failures, blockers, and important confirmations

## Output

Write execution results to plan store via `plan_revise`:

- Commands run
- Passed checks
- Failed checks
- Blocked checks
- Not tested
- Evidence (artifact paths)
- Recommended follow-up

## Auth

- Use auth state at `apps/playwright-tests/.auth/dev.json`
- Never run login or auth refresh
- Never read, print, or expose any file under `.auth/`
- If auth is missing or invalid, stop and return `auth-blocked`

## Artifacts

- Artifact dir: `$(dirname "$OPENCODE_PLAN_DB")/<plan_id>/`
- Create at start: `mkdir -p "$(dirname "$OPENCODE_PLAN_DB")/<plan_id>/"`
- Screenshots: `--filename="$(dirname "$OPENCODE_PLAN_DB")/<plan_id>/<name>.png"`
- Snapshots: `--filename="$(dirname "$OPENCODE_PLAN_DB")/<plan_id>/<name>.yaml"`
- Traces: `"$(dirname "$OPENCODE_PLAN_DB")/<plan_id>/trace.zip"`
- Reference artifact paths in plan store notes
- Never store artifacts in the repo or temp directories

## Rules

- Require a `plan_id` — stop and ask if missing
- Write all output to plan store via `plan_revise`
- Stop and surface blockers instead of guessing
- Never include secrets or auth material in output

Context: $ARGUMENTS
