---
name: jira-bug
description: Prepare a work Jira bug using the existing team template and create the completed draft only when authorized.
---

## Inputs

Observed problem, Jira site/project, environment/build, reproduction steps,
expected/actual results, evidence, and any technical context/preconditions.
Resolve actual Bug type and required fields from Jira metadata before creation.

## Procedure

1. Follow `references/plannotator-intake.md` for the existing Plannotator interview
   schema, result handling, metadata discovery, and exact team heading order.
   Run as builder. Keep per-bug artifacts in a fresh `work/jira-bugs/<draft-id>/`.
   Preserve supplied facts and use explicit unknowns; never invent reproduction.
2. Use `templates/bug.md` for the description. Include preconditions, observed
   impact, evidence and technical context under the appropriate existing headings.
   Omit blank optional links and retain the team's heading spelling/order.
3. Show the complete draft with destination, summary, resolved fields, and body.
   Plannotator `annotate --gate --json` remains the review UI when creation needs
   authorization. Apply annotations and review the corrected draft. Existing
   explicit authorization for this exact completed bug is sufficient; an intake
   form submission or initial bug context alone is not creation authorization.
4. Create once using the exposed `atlassian_createJiraIssue` schema after
   authorization. The configured tool rule is ask as the external write boundary.
   Use the declared description format (including ADF when required). Do not bypass
   it through CLI/browser or broad saved approval. Never automatically publish
   failure bugs produced by manual-testing.
5. Record the returned issue key and URL. After an ambiguous creation response,
   check for the created issue before retrying; if unresolved, stop to avoid a
   duplicate. A local save failure never justifies another creation call.

## Output and missing evidence

Return a complete bug draft and missing required fields, or the verified clickable
issue link after creation. Missing metadata or access blocks publication, not
drafting. Never invent an issue URL or report a draft as created.
