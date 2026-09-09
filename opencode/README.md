# OpenCode Configuration

Shared OpenCode configuration with separate work and personal profiles. OMO-slim provides reusable planning agents and background task management; OpenCode commands define workflows; Plannotator provides human review.

## Tested Baseline

| Component | Version |
|---|---|
| OpenCode | `1.18.30` |
| `oh-my-opencode-slim` | `2.2.18` |
| `@plannotator/opencode` | `0.27.12` |
| `@opencode-ai/plugin` for local tools | `1.18.23` |

Plugin entries are pinned in both profiles. OMO automatic updates are disabled so the configured schema and behavior do not drift independently.

## Layout

```text
opencode/
├── opencode.work.jsonc
├── opencode.personal.jsonc
├── oh-my-opencode-slim.jsonc
├── oh-my-opencode-slim/orchestrator.md
├── agent-defs/
├── commands/
├── skills/
├── tools/
├── sql/
├── package.json
└── tui.json
```

`OPENCODE_CONFIG_DIR` points directly at this directory. There is no second global OpenCode configuration layer.

## Profiles

`zsh/.zshenv` selects the profile and matching OMO preset together:

| Profile | OpenCode config | OMO preset | Providers |
|---|---|---|---|
| Work | `opencode.work.jsonc` | `work` | GitHub Copilot; Atlassian MCP enabled |
| Personal | `opencode.personal.jsonc` | `personal` | OpenAI and OpenCode; no work MCP |

The existing username rule selects personal for `klaus224` and work otherwise. `pair-programmer` remains the default agent in both profiles; OMO's `setDefaultAgent` is disabled.

For a one-off profile launch, set all three values together:

```bash
OPENCODE_CONFIG_DIR="$DOTFILES_HOME/opencode" \
OPENCODE_CONFIG="$DOTFILES_HOME/opencode/opencode.personal.jsonc" \
OH_MY_OPENCODE_SLIM_PRESET=personal \
OPENCODE_EXPERIMENTAL_BACKGROUND_SUBAGENTS=true \
opencode
```

Use the corresponding `work` values for the work profile.

## Planning Agents

The OMO pilot enables only:

| Agent | Purpose | Boundary |
|---|---|---|
| `orchestrator` | Execute declared command stages and reconcile results | Read-only; delegates only to `explorer` and `oracle`; can call `pr_context_get` and `submit_plan` |
| `explorer` | Inspect changed behavior and existing coverage | Read-only; no shell or delegation |
| `oracle` | Draft and independently critique plans | Read-only; no shell or delegation |

`librarian`, `designer`, `fixer`, `observer`, and `council` are disabled for this pilot. OMO background concurrency is capped at two tasks with a 15-minute wall-clock deadline. Periodic automatic continuation is disabled.

Native `planner` remains available for general conversational planning and Plannotator review. The existing `build`, `reviewer`, `jira-operator`, `test-orchestrator`, `playwright-user`, and `test-writer` roles remain temporarily registered but cannot be dispatched by the new orchestrator.

## Test Planning

```text
/test-plan 123 manual
/test-plan 123 unit
/test-plan 123 playwright
/test-plan https://github.com/owner/repo/pull/123 unit,playwright
```

The test type is required and is never inferred. The workflow:

1. Validates the PR source and selected test types.
2. Retrieves PR metadata, base/head SHAs, all changed-file pages, and available patches using `pr_context_get`.
3. Runs behavior and selected-type coverage discovery in parallel.
4. Uses Oracle to draft and a fresh Oracle session to review.
5. Allows one correction pass, submits Markdown directly through Plannotator, and stops.

The command never modifies application code, executes tests, opens a browser, publishes results, or authorizes later execution. Plannotator approval is review feedback only.

## Custom Tool

`tools/pr_context.ts` exposes `pr_context_get`. It accepts only a positive PR number or canonical GitHub PR URL and a non-empty set of `manual`, `unit`, and `playwright` categories. It invokes authenticated `gh` with argument arrays, paginates the files endpoint, caps output, observes cancellation/timeouts, and reports omitted patches explicitly.

Run local checks from this directory:

```bash
npm install --ignore-scripts
npm test
npm run typecheck
```

## Deprecated Workflows

`/regression-test` and `/parallel-ui-tests` are deprecation stubs. They do not invoke removed persistence tools or treat Markdown as executable authorization.

The old persistence executable, schema, and archived adapter were removed. Existing runtime databases outside this repository are untouched and are not used by this configuration.

## Retirement Gates

| Role | Remove after |
|---|---|
| `build` | OMO `fixer` has a separately approved implementation workflow and verified permissions |
| `reviewer` | Oracle review covers the required review behavior and useful feedback conventions have moved into shared guidance |
| `jira-operator` | Explicit Jira commands replace its operations; update `TODAY_AGENT_CMD` first |
| `test-orchestrator`, `playwright-user`, `test-writer` | General coordination/execution supports their required behavior and project auth leaves global prompts |
| Legacy test commands | Every supported input has a deliberate migration or explicit deprecation |

## Installation

Run `scripts/setup-opencode-cli.sh`. It installs OpenCode through Homebrew when needed, installs local tool dependencies without lifecycle scripts, and validates that the profile/configuration files exist. It does not adopt or overwrite files in another configuration directory.

Source `zsh/.zshenv` (normally through the repository's zsh setup) before launching OpenCode.

For startup recovery only:

```bash
OH_MY_OPENCODE_SLIM_DISABLE=1 opencode
```

This disables OMO-slim for that launch; it does not restore retired workflows.
