---
description: Run the manual testing workflow for one Jira ticket
agent: test-orchestrator
---

Run the manual testing workflow for exactly one Jira ticket.

## Input

Arguments must include:

- one Jira ticket key or Jira ticket link
- one Playwright base URL (the target URL to test against)

Examples:

- `/manual-test-single PROJ-123 https://dev.example.com`
- `/manual-test-single https://your-company.atlassian.net/browse/PROJ-123 https://dev.example.com`

## Flow

1. Parse the Jira input into a canonical ticket key.
2. Normalize the base URL.
3. Create a fresh `plan_id`.
4. Store ticket and base URL in the plan store.
5. Dispatch `jira-operator` to fetch ticket details.
6. Create a git worktree for isolation.
7. Dispatch `test-executor` to authenticate, plan, and execute tests.
8. Save the report to the plan-store DB directory.
9. Dispatch `jira-operator` to comment a summary on the ticket.
10. Clean up the worktree.
11. Return the final summary.

## Rules

- One run handles one ticket only.
- Do not discover multiple tickets.
- Do not batch runs.
- Stop and report missing or invalid input instead of guessing.

Context: $ARGUMENTS
