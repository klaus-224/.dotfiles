---
description: Fetch and Summarize Jira Ticket
agent: jira-operator
---

Fetch all Jira tickets assigned to the current user that are "In QC" using this JQL:

```jql
assignee = currentUser() AND status = "In QC" ORDER BY priority DESC, updated DESC
```

For each ticket, produce a summary with this structure:

---

## [TICKET-KEY] Title
- **Status:** <status>
- **Priority:** <priority>
- **Description:** <1-2 sentence summary of what the ticket is about>
- **Acceptance Criteria:** <bullet list if present, otherwise "Not specified">

### Linked PRs

Run: `gh pr list --search "<TICKET-KEY>" --json number,title,url,state`

For each PR found:
1. `gh pr view <number> --json title,body,state,baseRefName`
2. `gh pr diff <number>`

Then produce:
- **[#number title](url)** — `<state>` → `<baseRefName>`
  - **Summary:** <one sentence on what this PR does>
  - **Files changed:**
    - `<file-path>` — <one line: what changed and why it matters>
    - _(repeat for each file)_
  - **Risk areas:**
    - Flag any of: shared utilities, auth/session logic, DB migrations, config/env changes, broad refactors, deleted code, changes to hooks/middleware, side effects in event handlers
    - For each risk: `⚠️ <file or area>` — <why it's risky and what could break>
    - If no risks: "No significant risks identified"

If no PRs found: "None found"

### Comments / Notes
<Any recent comments worth surfacing, or "None">

---

Repeat for each ticket. If no tickets are found, say so plainly.
