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

- `/manual-test ION-1234 https://next.skyon.app`
- `/manual-test https://orennia.atlassian.net/browse/ION-1234 https://next.skyon.app`

## Flow

1. Parse the ticket key and base URL from arguments. If the ticket argument is a full URL, extract the key (last path segment).
2. Discover cloudId by calling `atlassian_getAccessibleAtlassianResources` — use the first result's id.
3. Dispatch `jira-operator` (Task tool) with prompt: `Fetch full details for ticket <TICKET> using cloudId <CLOUD_ID>. Return the ticket summary, description, acceptance criteria, and any linked issues.`
4. Receive ticket details from jira-operator.
5. Dispatch `test-executor` (Task tool) with a prompt containing: the full ticket details from step 4, the base_url, and the ticket key. Instruct it to create a test plan, get user review via the plannotator-annotate skill, then execute the approved plan using Playwright.
6. Return the executor's report to the user.

## Rules

- Exactly two sequential Task dispatches. Nothing else.
- If either agent returns an error, surface it and stop.
- Do not add logic, retries, or extra steps.
- Neither agent should use plan_store tools.

Context: $ARGUMENTS
