---
description: Create requirement-linked manual cases from supplied context or a work Jira ticket
agent: builder
---

Create a manual test plan for $ARGUMENTS. Load `jira-ticket` for a work Jira ticket
when available, `pr-review` for associated PR evidence, and `manual-test-plan`.
Return the plan in this session; write a file only if requested. Do not execute it.
