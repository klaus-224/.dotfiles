---
name: playwright-docs
description: Use when writing, reviewing, debugging, or planning Playwright tests, locators, fixtures, test config, auth setup, tracing, CLI usage, network mocking, or Playwright MCP/CLI workflows. Prefer local Playwright docs and project conventions over memory.
---

# Playwright Docs Skill

Use this skill when the task involves Playwright test authoring, debugging, configuration, or automation.

## Process

1. Search local Playwright docs first:
   - Run `playwright-docs search "<topic>"`.
   - Prefer `docs-src/*-js.md` and `docs-src/test-*.md` for TypeScript/JavaScript test work.
   - Prefer `docs-src/api/` and `docs-src/test-api/` for API details.

2. Read project-specific context:
   - `references/conventions.md`

3. Answer using this priority order:
   1. Project conventions
   2. Local Playwright docs
   3. General reasoning

4. When giving code:
   - Prefer existing project fixtures and helpers.
   - Prefer resilient locators.
   - Avoid arbitrary sleeps.
   - Use Playwright assertions instead of manual polling when possible.
   - Mention the exact doc file used when relevant.

## Example Usage

```zsh
# Search local docs
playwright-docs search "network interception"
playwright-docs search "locator filter"
playwright-docs search "auth setup"

# Sync latest docs from upstream
playwright-docs sync
# or to a custom directory:
playwright-docs sync ~/my-project/docs/playwright
```

## Do not

- Do not assume Playwright defaults if the project config overrides them.
- Do not recommend broad browser permissions or secret exposure.
- Do not use upstream Playwright contributor docs unless the user is modifying Playwright itself.
