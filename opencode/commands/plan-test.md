---
description: Produce a concise risk-focused manual test plan from stored Jira context
agent: test-planner
---

## Input

- `plan_id` is required

## Task

Read the current plan record and produce a concise manual test plan for execution.

Focus on:

- user-visible behavior
- acceptance criteria coverage
- highest-risk regression checks
- preconditions and setup
- blockers or missing context

## Output

Write the plan to the plan store via `plan_revise` using structured data including:

- ticket
- scope
- assumptions
- preconditions
- ordered_test_steps
- validations
- edge_checks
- blockers
- execution_notes

## Rules

- Require `plan_id`.
- Do not execute browser commands.
- Do not fetch Jira directly.
- Do not invent missing behavior.
- Stop and surface blockers when context is insufficient.

Context: $ARGUMENTS
