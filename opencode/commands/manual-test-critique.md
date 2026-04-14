---
description: Critique a manual test plan without executing
agent: manual-test-executor
---

## Input

- `plan_id` is required — the plan store contains the planner's draft

## Task

Review the test plan in the plan store. Do **not** run any tests or browser commands.

Evaluate:

- High-risk gaps the plan misses
- Low-value checks that should be dropped
- Ambiguous or untestable steps
- Missing preconditions or setup assumptions
- Priority ordering issues

## Output

Write critique to plan store via `plan_revise`:

- Gaps identified
- Checks to drop
- Checks to add
- Ambiguities flagged
- Suggested priority changes

## Rules

- Require a `plan_id` — stop and ask if missing
- Do **not** run any tests, browser commands, or Playwright CLI
- Write all output to plan store via `plan_revise`
- Never reference files under `.auth/`

Context: $ARGUMENTS
