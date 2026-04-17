---
description: Run the single-ticket manual testing workflow for one Jira ticket and one base URL
agent: test-orchestrator
---

Run the manual testing workflow for exactly one Jira ticket.

## Input

Arguments must include:

- one Jira ticket key or Jira ticket link
- one Playwright base URL

Examples:

- `/manual-test PROJ-123 https://dev.example.com`
- `/manual-test https://your-company.atlassian.net/browse/PROJ-123 https://dev.example.com`

## Flow

1. Parse the Jira input into a canonical ticket key.
2. Normalize the base URL.
3. Create a fresh `plan_id`.
4. Store ticket and base URL in the plan store.
5. Prepare shared auth.
6. Dispatch in order:
   - `/jira-fetch ticket=<ticket> plan_id=<plan_id>` via `jira-operator`
   - `/plan-test plan_id=<plan_id>` via `test-planner`
   - `/execute-test plan_id=<plan_id>` via `test-executor`
   - `/jira-comment plan_id=<plan_id>` via `jira-operator`
7. If execution returns `auth-blocked`, refresh auth once and retry execution once.
8. Return the final summary.

## Rules

- One run handles one ticket only.
- Do not discover multiple tickets.
- Do not batch runs.
- Do not run a critique/revision loop.
- Stop and report missing or invalid input instead of guessing.

Context: $ARGUMENTS
