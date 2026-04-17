---
description: Post a final Jira comment from execution results stored in the plan store
agent: jira-operator
---

## Input

- `plan_id` is required

## Task

Read stored execution results and post a concise Jira comment for the ticket in the plan.

The comment should include:

- what was tested
- pass, fail, and blocker summary
- important evidence references
- follow-up recommendation when needed

## Rules

- Require `plan_id`.
- Comment only from validated execution results.
- Do not invent results.
- Do not transition ticket status.
- Keep the comment concise and operational.

Context: $ARGUMENTS
