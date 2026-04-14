---
description: Draft or revise a manual test plan for a ticket
agent: manual-test-planner
---

## Input

- `plan_id` is required — the plan store already contains ticket context
- `mode`: `draft` (default) or `revise`

## Draft mode

Turn the ticket context in the plan store into a test plan:

- Focus on changed behavior, regression risk, user-visible impact, failure modes
- Use linked PR context when available
- Separate checks by priority: P0 (critical), P1 (important), P2 (nice-to-have)
- Make checks executable: key flows, expected outcomes, setup assumptions
- If context is missing, say what's missing and how it lowers confidence

## Revision mode

When `mode=revise`, the plan store contains executor critique:

- Produce one tighter revision addressing the critique
- Do not restate the first draft — only refine
- Drop checks flagged as low-value, add checks identified as missing

## Output format

Write to plan store via `plan_revise`:

- Goal
- Context summary
- Assumptions / prerequisites
- High-risk areas
- Ordered test plan (P0 → P1 → P2)
- Risks / open questions

## Rules

- Require a `plan_id` — stop and ask if missing
- Write all output to plan store via `plan_revise`
- Do not fetch Jira details — use what the plan store contains
- Do not edit repo files
- Never reference files under `.auth/`

Context: $ARGUMENTS
