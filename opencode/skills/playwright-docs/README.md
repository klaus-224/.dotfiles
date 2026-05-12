# playwright-docs skill

An OpenCode skill that gives agents access to local Playwright documentation for accurate, offline-first answers when writing, reviewing, or debugging Playwright tests.

## What it does

- Searches a local snapshot of the official Playwright docs (`references/docs-src/`)
- Surfaces project conventions from `references/conventions.md`
- Guides agents to prefer resilient locators, built-in assertions, and existing fixtures

## Structure

```
playwright-docs/
├── SKILL.md              # Skill definition loaded by OpenCode
├── references/
│   ├── docs-src/         # Synced Playwright upstream docs (markdown)
│   ├── conventions.md    # Project-specific Playwright conventions
│   └── UPSTREAM_COMMIT   # Git SHA of the last synced Playwright commit
└── scripts/
    └── playwright-docs   # Combined CLI: sync docs and search them
```

## Setup

1. Add the script to your `$PATH` (e.g. symlink into `~/.local/bin`):

   ```zsh
   ln -sf ~/.dotfiles/opencode/skills/playwright-docs/scripts/playwright-docs ~/.local/bin/playwright-docs
   ```

2. Set the docs directory (add to `.zshenv` or similar):

   ```zsh
   export PLAYWRIGHT_DOCS_DIR="$HOME/.dotfiles/opencode/skills/playwright-docs/references/docs-src"
   ```

3. Sync docs from upstream (requires internet):

   ```zsh
   playwright-docs sync
   ```

   This clones a sparse checkout of `microsoft/playwright` into `~/.cache/playwright-upstream` and copies `docs/src/` into the target directory.

## Updating docs

```zsh
playwright-docs sync
```

The synced commit is recorded in `references/UPSTREAM_COMMIT`.

## Searching docs manually

```zsh
playwright-docs search "network interception"
playwright-docs search "locator filter"
```

Returns up to 120 lines of matching context from all markdown files under `docs-src/`.

## Syncing to a custom directory

You can override the target directory per-invocation without changing the env var:

```zsh
playwright-docs sync ~/my-project/docs/playwright
```

## When this skill is loaded

OpenCode loads this skill automatically when the task involves:

- Writing or reviewing Playwright tests
- Debugging flaky selectors or assertions
- Configuring `playwright.config.ts`
- Auth setup, tracing, CLI usage, or network mocking
