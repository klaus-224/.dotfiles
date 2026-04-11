# Neovim 0.12.1 Migration Plan

## Goal

Make this config fully and intentionally compatible with Neovim `0.12.1`, with one plugin management path, a reproducible lockfile, and a small smoke-test checklist for future upgrades.

## Current State

Observed in this repo:

- `nvim --version` reports `NVIM v0.12.1`.
- `nvim --headless '+quit'` succeeds with no startup error.
- `init.lua` uses native `vim.pack.add(...)`.
- `lua/config/lazy.lua` and `lazy-lock.json` still exist.
- Most plugin definitions still live in `lua/plugins/*.lua` in `lazy.nvim` spec format.
- Only three packages are currently tracked in `nvim-pack-lock.json`: `alpha-nvim`, `nvim-lspconfig`, and `nvim-treesitter`.
- Plugin commands that should exist if the `lua/plugins/*.lua` specs were loaded do not currently exist at startup:
  - `:Telescope` -> missing
  - `:Mason` -> missing
  - `:Lazy` -> missing
  - `:TSUpdate` -> present
- LSP config is already using the newer native API in `lua/lsp/enable.lua`:
  - `vim.lsp.config(...)`
  - `vim.lsp.enable(...)`
- `lua/plugins/treesitter.lua` already carries a Neovim `0.12.1` workaround for markdown/vimdoc injections.

## Main Finding

This is not primarily a "version bump" migration anymore. The editor is already running `0.12.1`.

The real remaining work is to finish the config migration so that the repo is consistently `0.12.1`-native instead of being split between:

- native `vim.pack`
- old `lazy.nvim` plugin specs

## Recommendation

Finish the migration to native `vim.pack` and retire `lazy.nvim` from this repo.

Reason:

- the repo is already partially moved there
- the LSP layer is already using modern Neovim APIs
- staying half on `vim.pack` and half on `lazy.nvim` is the largest current source of confusion and drift

## Non-Goals

- major UI redesigns
- replacing stable plugins without a concrete compatibility problem
- broad refactors outside plugin/bootstrap, LSP wiring, and verification

## Phase 1: Baseline And Safety

1. Capture a before-state checklist.
2. Confirm which workflows must survive the migration.
3. Keep rollback simple until the new path is stable.

Concrete work:

- Record current startup and command checks:
  - `nvim --headless '+quit'`
  - `nvim --headless '+lua print(vim.fn.exists(":Telescope"))' '+qall'`
  - `nvim --headless '+lua print(vim.fn.exists(":Mason"))' '+qall'`
- List critical user workflows to preserve:
  - LSP attach
  - completion via `blink.cmp`
  - formatting via `conform.nvim`
  - linting via `nvim-lint`
  - Telescope pickers
  - Oil file explorer
  - Rust flow via `rustaceanvim`
  - custom local plugins in `lua/custom/plugins/*`

Acceptance criteria:

- A short checklist exists for "works before / works after".

## Phase 2: Choose One Plugin System

Recommended target: native `vim.pack` only.

Concrete work:

1. Replace the ad hoc package list in `init.lua` with a real native package bootstrap layout.
2. Decide how plugin declarations will be stored:
   - either keep `lua/plugins/*.lua` and adapt them to a `vim.pack`-driven loader
   - or move them into a new native package declaration module
3. Make `nvim-pack-lock.json` the only authoritative lockfile.
4. Remove `lazy-lock.json` only after the native setup is verified.

Files directly involved:

- `init.lua`
- `lua/config/lazy.lua`
- `lazy-lock.json`
- `nvim-pack-lock.json`
- all files in `lua/plugins/*.lua`

Acceptance criteria:

- There is one clear startup path.
- A new contributor can tell how plugins load by reading `init.lua` and one plugin bootstrap module.

## Phase 3: Port Plugin Specs To The Native Loader

This is the core migration step.

Concrete work:

1. Inventory the plugins currently defined under `lua/plugins/`.
2. Port each plugin's:
   - source
   - dependencies
   - load triggers
   - config callback
   - build step
3. Port local plugins currently declared with `dir = "~/.dotfiles/..."` so they still load correctly under the native system.
4. Preserve lazy-loading only where it is actually useful.

Priority order:

1. foundation
2. editing and navigation
3. language tooling
4. custom local plugins

Foundation:

- colorscheme
- statusline
- alpha
- treesitter
- comments
- surround
- autopairs

Editing and navigation:

- telescope
- flash
- oil
- tmux navigator
- blame

Language tooling:

- mason
- mason-tool-installer
- lazydev
- blink
- conform
- nvim-lint
- rustaceanvim

Custom local plugins:

- `lua/custom/plugins/git-pr.nvim`
- `lua/custom/plugins/pr-diff-loclist.nvim`

Acceptance criteria:

- Commands for migrated plugins exist after startup.
- Plugin config callbacks are actually executed.
- The native lockfile includes the full plugin set.

## Phase 4: Re-Verify 0.12.1 API Usage

The LSP layer already looks close to the desired state, so this phase should stay small.

Concrete work:

1. Keep `vim.lsp.config(...)` and `vim.lsp.enable(...)` as the default path.
2. Confirm no remaining plugin code assumes the old `lspconfig` setup style is required at runtime.
3. Verify `blink.cmp` capability wiring still works through `lua/lsp/capabilities.lua`.
4. Re-check Treesitter behavior on markdown/help buffers because the repo already carries a specific `0.12.1` workaround.
5. Audit for dead migration leftovers after plugin bootstrap is stable.

Files to revisit:

- `lua/lsp/enable.lua`
- `lua/lsp/capabilities.lua`
- `lua/plugins/treesitter.lua`
- `lua/core/options.lua`

Acceptance criteria:

- No startup warnings from LSP bootstrap.
- LSP attaches in representative filetypes.
- Markdown/help buffers do not regress or crash.

## Phase 5: Verification Matrix

Run a small set of checks after the migration.

Startup:

- `nvim --headless '+quit'`
- `nvim --headless '+lua print(vim.fn.exists(":Telescope"), vim.fn.exists(":Mason"), vim.fn.exists(":ConformInfo"), vim.fn.exists(":Oil"))' '+qall'`

Interactive smoke tests:

- open a Lua file and confirm Lua LSP attaches
- open a TypeScript file and confirm `ts_ls` attaches
- run formatting on Lua, TypeScript, and Python
- run a Telescope picker
- open Oil
- trigger completion with `blink.cmp`
- open a markdown or help buffer and verify Treesitter remains stable

If available, also verify with a clean data directory to catch hidden machine-local state.

Acceptance criteria:

- All critical commands exist.
- No startup errors.
- No broken keymaps for core workflows.
- No crash/regression in markdown/help parsing.

## Phase 6: Cleanup

Concrete work:

1. Delete `lua/config/lazy.lua` if it is no longer part of the supported path.
2. Delete `lazy-lock.json` once the native lockfile is complete and verified.
3. Remove commented bootstrap leftovers such as `-- require("config.lazy")` from `init.lua`.
4. Add one short maintenance note describing:
   - how to add plugins
   - how to update the native lockfile
   - what smoke tests to run after updates

Acceptance criteria:

- No dead bootstrap code remains.
- The repo documents one supported plugin/update workflow.

## Risks

1. Plugin loading semantics may change when moving away from `lazy.nvim`.
2. Startup time can regress if everything becomes eager-loaded by default.
3. Local custom plugins may break if native path handling is not mirrored correctly.
4. Mason and tool installers can appear healthy at startup while still failing later in real project buffers.
5. Treesitter behavior in markdown/help remains a known sensitive area on `0.12.1`.

## Suggested Execution Order

1. baseline checks
2. native plugin bootstrap module
3. port foundation plugins
4. port Telescope/Oil/navigation plugins
5. port LSP/completion/formatting plugins
6. port local custom plugins
7. run smoke tests
8. remove `lazy.nvim` leftovers

## Definition Of Done

The migration is done when:

- the repo has one plugin manager path
- all intended plugins load from that path
- `nvim-pack-lock.json` is the only lockfile
- the LSP/completion/formatting stack works on representative files
- markdown/help buffers are stable on `0.12.1`
- dead `lazy.nvim` bootstrap files are removed
