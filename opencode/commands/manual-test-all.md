---
description: Run the manual testing workflow for all Jira tickets assigned to me
agent: test-orchestrator
---

Run the manual testing workflow for all Jira tickets assigned to the current user.

## Input

Arguments must include:

- one Playwright base URL (the target URL to test against)

Examples:

- `/manual-test-all https://dev.example.com`

## Flow

1. Normalize the base URL.
2. Dispatch `jira-operator` to query all tickets assigned to me.
3. For each ticket (max 10 in parallel):
   a. Create a fresh `plan_id`.
   b. Dispatch `jira-operator` to fetch ticket details.
   c. Create a git worktree for isolation.
   d. Dispatch `test-executor` to authenticate, plan, and execute tests.
   e. Save the report to the plan-store DB directory.
   f. Dispatch `jira-operator` to comment a summary on the ticket.
   g. Clean up the worktree.
4. Return a consolidated summary.

## Rules

- Max 10 tickets in parallel.
- Each ticket gets its own `plan_id` and worktree.
- Stop and report missing or invalid input instead of guessing.

Context: $ARGUMENTS
