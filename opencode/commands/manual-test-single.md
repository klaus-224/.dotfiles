---
description: Run manual testing for one Jira ticket
agent: general
---

Run the manual testing workflow for one Jira ticket.

## Input

Arguments: `<TICKET> <BASE_URL>`

- One Jira ticket key or link
- One base URL to test against

Examples:

- `/manual-test-single ION-1234 https://next.skyon.app`
- `/manual-test-single https://orennia.atlassian.net/browse/ION-1234 https://next.skyon.app`

## Flow

1. Parse the ticket key and base URL from arguments.
2. Dispatch `test-planner` (Task tool) with prompt: `ticket=<TICKET> base_url=<BASE_URL>`
3. Receive `plan_id` from planner.
4. Dispatch `test-executor` (Task tool) with prompt: `plan_id=<plan_id>`
5. Return the executor's report to the user.

## Rules

- Exactly two sequential Task dispatches. Nothing else.
- If either agent returns an error, surface it and stop.
- Do not add logic, retries, or extra steps.

Context: $ARGUMENTS
