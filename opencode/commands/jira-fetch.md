---
description: Fetch full Jira ticket context including PR links and comments
agent: jira-operator
---

Fetch all details for Jira ticket: $ARGUMENTS

Collect:
- Summary, description, status, priority, assignee
- All comments (summarize long threads, keep recent ones verbatim)
- Linked PRs / remote links
- Subtasks and linked issues
- Acceptance criteria (if present in description or custom fields)

Return a single structured block:

```
ticket_key: ...
summary: ...
status: ...
priority: ...
assignee: ...
description_summary: ...
acceptance_criteria: [...]
comments_summary: ...
recent_comments: [...]
pr_links: [...]
linked_issues: [...]
subtasks: [...]
blockers: [...]
```

Do not create or modify any plans. Do not delegate. Do not invent data. Just fetch and return.
