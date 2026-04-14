---
description: Run the manual testing workflow for Jira tickets
agent: manual-test-orchestrator
---

Run the manual testing workflow.

## Startup

- Ask the user for the **base URL** if not provided in `$ARGUMENTS`
- Parse ticket keys from `$ARGUMENTS`, or delegate to `jira-operator` to list assigned tickets and let the user choose
- Run the auth tool once with the base URL

## Fetch + plan creation

For each selected ticket:
- Delegate to `jira-operator` with `/jira-fetch TICKET-KEY`
- Create one `plan_id` per ticket (`task_key` = ticket key, base URL in goal)
- Write the fetched ticket context into the plan via `plan_revise`

## Per-ticket workflow

Run tickets **in parallel** — steps within a ticket are serial:

1. **Plan** — delegate to `manual-test-planner` with `/manual-test-plan plan_id=<plan_id>`
2. **Critique** — delegate to `manual-test-executor` with `/manual-test-critique plan_id=<plan_id>`
3. **Revise** — delegate to `manual-test-planner` with `/manual-test-plan plan_id=<plan_id> mode=revise`
4. **Execute** — delegate to `manual-test-executor` with `/manual-test-execute plan_id=<plan_id>`
5. **Report** — delegate to `jira-operator` with `/jira-comment plan_id=<plan_id>`

## Auth recovery

- If any executor returns `auth-blocked`: re-run auth once, retry only the blocked execution
- Do not re-run earlier steps during recovery
- If still blocked after one retry, stop that ticket and report the blocker

## Rules

- You own auth — never delegate it to sub-agents
- Every delegation must include a `plan_id`
- One plan-store record per ticket — never share across tickets
- Parallelism is across tickets, not within a ticket
- One critique + one revision per ticket max — do not loop
- Do not ask Jira to transition ticket status
- Stop and report if required context is missing

## Return

- Ticket list (discovered + selected)
- Per-ticket: plan summary, execution result, Jira comment status
- Any blockers encountered

Context: $ARGUMENTS
