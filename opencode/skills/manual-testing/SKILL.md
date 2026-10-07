---
name: manual-testing
description: Execute an existing manual test plan in an authorized test environment and report PASS, FAIL, or BLOCKED with evidence.
---

## Inputs

Plan or ticket, environment URL/build, authorized test account/role, test data,
and evidence destination. Use builder because evidence capture writes artifacts
and browser actions may mutate application state. Load work `jira-ticket` and
`manual-test-plan` only when a plan needs to be prepared first.

## Procedure

1. Inspect project instructions and confirm deployed build, case prerequisites,
   authorized environment/data, and available browser integration. Use one
   configured browser route: work Playwright MCP when enabled, otherwise explicitly
   established project tooling. Load `playwright-cli` only for an approved CLI
   route; never use it to bypass an MCP denial.
2. Use the existing authenticated test session or have the user sign in. Do not
   read credentials or export cookies/storage state into Git. Ask before changes
   outside the authorized test data/environment or newly consequential actions.
3. Execute each case's steps and record actual observations against expected
   results. Capture relevant screenshots/traces in the agreed artifact directory,
   avoiding secrets and private account information. Evidence IDs point to actual
   artifacts, never imagined captures. Stop dependent cases when prerequisites fail.
4. Report PASS only after all observable expectations were checked, FAIL for a
   demonstrated mismatch, and BLOCKED for missing access/data/build/tooling or an
   unexecuted required step. Include expected versus actual and precise blockers.
5. Draft bugs for failures with the work jira-bug template when available; do not
   create issues automatically. Perform only authorized cleanup.

## Output and missing evidence

Use `templates/report.md`: environment/build, plan/source revisions, execution
time, per-case status, expected/actual results, evidence, cleanup and coverage gaps.
Missing browser access leaves cases BLOCKED; it never counts as a pass.
