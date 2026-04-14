---
description: Post validated manual test results as a Jira comment
agent: jira-operator
---

## Input

- `plan_id` is required — the plan store contains execution results

## Task

Read execution results from the plan store and post a concise comment on the Jira ticket.

Comment should include:
- Tested scope
- Outcome (pass / fail / partial)
- Key findings
- User impact
- Next action

## Rules

- Only use validated execution findings — do not invent results
- Do not transition the ticket or change its status

Context: $ARGUMENTS
