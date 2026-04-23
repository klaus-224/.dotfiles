---
description: Fetch Jira ticket context for one ticket and persist it into the plan store
agent: jira-operator
---

## Input

Either:

- `ticket` and `plan_id` -- fetch one ticket and store context in the plan
- `assigned_to_me` -- query all tickets assigned to the current user and return the list

## Task

### Single ticket mode

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
- linked_issues (including linked PRs)
- subtasks
- blockers

### Assigned-to-me mode

Query Jira for all tickets assigned to the current user. Return the list of ticket keys and summaries.

## Output

- Single ticket: Write fetched Jira context into the plan store via `plan_revise`.
- Assigned-to-me: Return the list of ticket keys and summaries.

## Rules

- Single ticket mode requires both `ticket` and `plan_id`.
- Do not create a new plan.
- Do not delegate.
- Do not invent missing Jira data.
- Do not transition ticket status.

Context: $ARGUMENTS
