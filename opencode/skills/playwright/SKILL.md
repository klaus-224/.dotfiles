---
name: playwright
description: Write or review project Playwright tests for correctness, coverage, isolation and flakiness.
---

## Inputs

Ticket/change/scope or PR/diff, repository instructions, existing test config and
fixtures, expected behavior, and available test environment. In work scope load
`jira-ticket` for a supplied ticket; otherwise use supplied requirements and PR
evidence from `pr-review`. Browser MCP access does not validate project tests.

## Procedure

1. Inspect the actual Playwright config, package scripts, fixture extensions,
   auth/roles, data factories, existing tests and impacted code. Preserve project
   conventions and pnpm preferences. Use `find-docs` for pinned API behavior.
2. Map requirements/risks to existing coverage and gaps. Write tests under builder
   only; reviewer/chat/explore perform read-only review and never execute tests.
3. Reuse established fixtures and independent test data. Prefer role/label/test-id
   locators and auto-waiting assertions. Avoid fixed sleeps, brittle selectors,
   order dependence, shared mutable accounts, hidden retries, and test.only.
   Cover meaningful failures and role boundaries supported by the requirements.
4. For writing, run the established targeted command, e.g.
   `pnpm exec playwright test <validated test path>`, plus relevant project checks.
   Inspect the actual result and artifacts. Installs and unfamiliar commands retain
   their approval gate. Missing secrets/environment/data are blockers, not grounds
   to weaken assertions, skip failures silently, or claim a pass.
5. For review, prioritize correctness, criterion coverage, fixture/data isolation,
   flakiness, and cleanup. Cite file/line evidence and the triggering condition.
   Distinguish static review from execution. Do not publish a PR comment/review.

## Output and missing evidence

Report tests changed or findings in severity order, requirement-to-test mapping,
actual commands/results, skipped coverage and concrete blockers. A blocked run
does not establish that tests pass. Return findings directly; builder owns fixes.
