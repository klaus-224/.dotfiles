---
name: jira-ticket
description: Retrieve Jira requirements, comments and linked PR evidence for a work ticket or test workflow.
---

## Inputs

Ticket key/URL, Jira site if ambiguous, repository hints, and requested outcome.
Use the exposed Atlassian tool schemas; permission names are not tool discovery.

## Procedure

1. Discover accessible sites and resolve the requested ticket. Read description,
   acceptance criteria, environment/build details, comments, and remote links.
   Follow pagination and note inaccessible sources. Never guess a cloud ID/key.
2. Assign stable AC IDs while preserving authoritative wording and source links.
   Separate explicit requirements, inferred intent, contradictions, and questions.
3. Find linked PRs from remote links, development info, comments, and supplied
   URLs. Validate repository identity and linkage; a ticket-key search hit alone
   does not establish relevance. Load `pr-review` and record base/head revisions,
   changed files, relevant implementation, tests, and incomplete coverage.
4. Return the ticket and PR evidence directly. Never update Jira, publish comments,
   trigger implementation, or hand off to a planner merely to display the result.

## Output and missing evidence

Ticket URL, retrieval time, AC IDs, comments considered, PR inventory/revisions,
implementation mapping, unresolved ambiguities, and source completeness. If Jira
or PR access is unavailable, label the missing evidence and any requirements-only
draft explicitly; do not invent expected behavior or claim complete coverage.
