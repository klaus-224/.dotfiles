# Playwright Test Agent Guide

Write and maintain end-to-end tests in `apps/playwright-tests/`.

## Before Writing Tests

- Read the relevant Svelte code in `apps/skyon/` to understand the user flow and expected behavior.
- Grep `apps/skyon/` for `data-testid` values and check `data-testid-catalog.json`.
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
