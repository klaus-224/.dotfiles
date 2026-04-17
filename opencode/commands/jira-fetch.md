---
description: Fetch Jira ticket context for one ticket and persist it into the plan store
agent: jira-operator
---

## Input

- `ticket` is required
- `plan_id` is required

## Task

Fetch Jira context for the provided ticket and write it into the plan store.

Capture:

- key
- summary
- status
- priority
- assignee
- description_summary
- acceptance_criteria
- recent_comments
- linked_issues
- subtasks
- blockers

## Output

Write fetched Jira context into the plan store via `plan_revise`.

## Rules

- Require both `ticket` and `plan_id`.
- Do not create a new plan.
- Do not delegate.
- Do not invent missing Jira data.
- Do not transition ticket status.

Context: $ARGUMENTS
