---
description: Run manual testing for all Jira tickets assigned to me
agent: general
---

Run the manual testing workflow for all Jira tickets assigned to the current user.

## Input

Arguments: `<BASE_URL>`

- One base URL to test against

Examples:

- `/manual-test-all https://next.skyon.app`

## Flow

1. Parse the base URL from arguments.
2. Query Jira for all tickets assigned to current user (use Atlassian tools, JQL: `assignee = currentUser() AND status != Done ORDER BY priority DESC`).
3. For each ticket (max 10):
   a. Dispatch `test-planner` (Task tool) with prompt: `ticket=<TICKET> base_url=<BASE_URL>`
   b. Receive `plan_id` from planner.
   c. Dispatch `test-executor` (Task tool) with prompt: `plan_id=<plan_id>`
   d. Collect result.
4. Return a consolidated summary of all results.

## Rules

- Max 10 tickets.
- Each ticket is planned and executed sequentially (planner then executor) but tickets can run in parallel.
- If one ticket fails, continue with the others and report the failure.
- Do not add retries or extra steps.

Context: $ARGUMENTS
