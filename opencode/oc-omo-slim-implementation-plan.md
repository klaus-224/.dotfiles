# OMO-slim + declarative workflows: implementation plan

## Implemented pilot architecture

Use OMO-slim for reusable read-only planning agents, model routing, and background task management. Define workflow stages in OpenCode commands and submit final plans directly through Plannotator. Do not maintain a second plan database, approval-state machine, scheduler, or CLI adapter.

The first deliverable is `/test-plan <PR> <manual|unit|playwright>`. It produces a reviewable plan without running tests or changing application code. `pair-programmer` remains the default agent in both profiles.

## Tested baseline

| Component | Tested version |
|---|---|
| OpenCode | `1.18.30` |
| OMO-slim | `2.2.18` |
| Plannotator | `0.27.12` |

The work profile uses GitHub Copilot models; the personal profile uses OpenAI models. `OH_MY_OPENCODE_SLIM_PRESET` is selected alongside `OPENCODE_CONFIG`. Plugins are pinned and OMO automatic updates are disabled.

## Ownership

| Concern | Owner |
|---|---|
| Agent sessions, task lifecycle, concurrency, model routing | OMO-slim |
| Objective, selected test types, stage order and required outputs | OpenCode command definitions |
| PR metadata, changed-file inventory and available patches | Narrow `pr_context_get` tool |
| Investigation | `explorer` |
| Planning and independent critique | Separate `oracle` invocations |
| Test methodology and output structure | `test-planning` skill |
| Human plan review and review artifacts | Plannotator |

Commands are prompt contracts, not a deterministic DAG runtime. Tool permissions enforce concrete boundaries; agents execute the declared order and surface incomplete work.

## Permission boundary

- `orchestrator` is read-only, has no shell, and delegates only to `explorer` and `oracle`.
- `explorer` and `oracle` are read-only, have no shell, and cannot delegate.
- Only the coordinator can call `pr_context_get` and `submit_plan`.
- `librarian`, `designer`, `fixer`, `observer`, and `council` are disabled during the pilot.
- Work-only Atlassian access is not inherited by the personal profile.
- OMO does not replace `pair-programmer` as OpenCode's default agent.
- Planning cannot edit code, run tests, use a browser, publish results, or authorize execution.

## `/test-plan` contract

```text
/test-plan 123 manual
/test-plan 123 unit
/test-plan 123 playwright
/test-plan https://github.com/owner/repo/pull/123 unit,playwright
```

Test types are a required non-empty subset of `manual`, `unit`, and `playwright`. There is no automatic selection. An unsuitable category produces a coverage limitation, not an unsolicited replacement category.

| Stage | Agent/tool | Depends on | Output |
|---|---|---|---|
| Resolve | Orchestrator + `pr_context_get` | Valid input | PR identity, base/head SHAs, changed-file inventory, completeness markers |
| Behavior discovery | `explorer` | Resolve | Code-backed behaviors, risks, references and changed-file ledger |
| Coverage discovery | `explorer` | Resolve | Existing coverage and conventions only within selected types |
| Plan | `oracle` | Both discovery results | Typed scenarios, expected outcomes and limitations |
| Review | Fresh `oracle` | Plan and discovery evidence | Defects, missing evidence and category violations |
| Present | Orchestrator + `submit_plan` | Review and at most one correction pass | Markdown submitted to Plannotator; stop |

Only the two discovery stages run in parallel. Every delegation carries source identity, immutable selected types, bounded evidence and required outputs. Every changed file is inspected, excluded with a reason, or unresolved. Missing patches and missing checkout context remain visible.

Each scenario contains a stable ID, exactly one selected type, behavior/rationale, preconditions, actions, expected results, source references and a suggested location where applicable.

## Delivered files

| Path | Purpose |
|---|---|
| `opencode/opencode.work.jsonc`, `opencode/opencode.personal.jsonc` | Pinned plugins, provider separation and native-agent permissions |
| `opencode/oh-my-opencode-slim.jsonc` | Work/personal presets, agent restrictions, concurrency and feature selection |
| `opencode/oh-my-opencode-slim/orchestrator.md` | Declared-workflow coordinator contract |
| `opencode/commands/test-plan.md` | Planning workflow and output contract |
| `opencode/tools/pr_context.ts` | Read-only typed PR retrieval through authenticated `gh` |
| `opencode/skills/test-planning/SKILL.md` | Scenario quality and category constraints |
| `opencode/tests/pr_context.test.ts` | Source and test-type parser checks |
| `scripts/setup-opencode-cli.sh`, `opencode/README.md` | Actual installation, launch and operating guidance |

The old plan-store binary, SQLite schema and archived adapter are intentionally removed. `/regression-test` and `/parallel-ui-tests` are deprecation stubs and cannot execute their former workflows.

## Acceptance checks

| Check | Expected result |
|---|---|
| Missing or invalid type | Clear error before PR retrieval |
| Single and mixed requests | Only explicitly selected categories appear |
| Inappropriate requested category | Coverage limitation without replacement category |
| Planning permission probes | Edits, shell, browser, writer dispatch and publishing denied |
| Delegated permission probes | Workers remain read-only and cannot delegate |
| Large or incomplete PR | Missing patches/files remain visible; no unsupported completeness claim |
| Background failure or timeout | Failure remains visible; dependent stages stop |
| Work and personal launches | Intended providers/presets/MCPs, one agent registration, `pair-programmer` default |
| Plannotator approval | Workflow stops; no implementation or execution follows |

## Retirement roadmap

These existing roles are temporary and should be removed when their replacement boundary is implemented and verified:

| Retire | Gate |
|---|---|
| `build` | Separately approved OMO `fixer` implementation workflow |
| Interactive `reviewer` | Oracle review plus shared feedback guidance covers the useful behavior |
| `jira-operator` | Explicit Jira commands exist; update `TODAY_AGENT_CMD` first |
| `test-orchestrator`, `playwright-user`, `test-writer` | General execution has explicit authorization and project-scoped auth/configuration |
| Legacy test commands | Supported inputs are migrated or explicitly deprecated |

Future `/review-pr`, `/implement`, and execution workflows can reuse this composition, but execution authorization must be designed separately. Do not reintroduce a custom plan store, fork, second scheduler, or arbitrary-Markdown execution path.
