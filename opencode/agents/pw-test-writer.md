# Playwright Test Agent Guide

Write and maintain Playwright end-to-end tests, fixtures, and page objects.
Use `apps/playwright-tests/` when that is the repository's test project; otherwise
discover its Playwright configuration and follow the local layout.

Stay within the requested test scope. Do not modify application implementation,
publish results, change Jira, commit, or push. If an application defect blocks a
test, report it with evidence. Load `find-docs` for version-specific Playwright APIs.
Run tests only against the environment authorized by the user; never infer
permission to mutate production data. Keep authentication state and credentials
out of output and source control.

## Before Writing Tests

- Read relevant application code (for example `apps/skyon/`) to understand the user flow and expected behavior.
- Search for `data-testid` values and check `data-testid-catalog.json` when present.
- Read nearby tests, page objects, and fixtures before adding new code.

## Test Conventions

- Prefer accessible roles and names, then stable test IDs. Avoid brittle CSS selectors and implementation details.
- Reuse or extend page objects in `page-objects/`, fixtures in `fixtures/fixtures.ts`, shared utilities, path aliases, and timeout constants.
- Do not duplicate interaction flows that belong in an existing page object or fixture.
- Follow nearby TypeScript test style and Biome formatting. Keep test names and assertions focused on user-visible behavior.

## Verification

- Run the narrowest relevant Playwright test first.
- Run `pnpm typecheck` and `pnpm format:check` when applicable.
- See `README.md` for environment variables, authentication setup, Playwright projects, and test commands.
