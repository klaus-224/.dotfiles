# OpenCode v2 configuration

These profiles target OpenCode 2.0.20. Homebrew manages the executable and
OpenCode self-updating is disabled.

Each profile points `$schema` at its local `opencode.schema.json` for editor
completion. These files are generated from the pinned `@opencode/schema@2.0.20`
package with `pnpm schema:generate`, because the published
`https://opencode.ai/config.json` currently omits V2 configuration fields.

| Profile | Machine user | Providers | Additional agents |
| --- | --- | --- | --- |
| `personal/opencode.jsonc` | `klaus224` | OpenAI, OpenCode | `audit-orchestrator`, `audit-worker` |
| `work/opencode.jsonc` | `rohineshram` | GitHub Copilot | `ticket-review`, `pr-review`, `test-planner`, `jira-operator` |

Both profiles start with `chat` and include `planner`, `explorer`, and `builder`.
Models and variants remain profile-specific. Availability depends on the
provider account; validation does not authenticate or run a model.

## Loading and retained resources

Home Manager links `~/.config/opencode` to the profile selected by username in
`nix/home/files.nix`: `personal` for `klaus224`, `work` for other users. Zsh
does not override OpenCode's config path, so the Home Manager link is the single
profile selector.

Each profile owns its active `opencode.jsonc` and `cli.json`, while the shared
`prompts` and `skills` directories are linked into both profiles. File
references resolve from the profile directory. Agent registrations live in the
profile JSONC; retained prompt and skill libraries may include resources that
are not currently enabled for an agent.

The personal profile loads the local V2 `pr-context` plugin and exposes the
read-only `pr_context_get` tool only to `planner`. It accepts a PR number or
canonical GitHub PR URL plus the requested `manual`, `unit`, and/or `playwright`
test types. Its result includes PR revisions, changed files, bounded patches,
and explicit completeness markers.

The active package plugin is `@plannotator/opencode@0.27.22`. Retained prompt
files include the Jira, orchestration, and test-plan workflows. The work
profile also retains the six prompts in `prompts/back/` for its existing
workflows. All existing skill directories remain available. V1 tools,
archived commands, and the old root terminal client configuration were removed.

## Workflows and permissions

Permissions use V2 ordered rules: broad defaults precede specific exceptions,
and the last matching rule wins. Shell and delegation actions are `shell` and
`subagent`. Planning and review agents retain their read-only restrictions.

Work's `/test-plan` retrieves Jira requirements, delegates PR inspection to
`pr-review`, and passes findings to `test-planner`. It returns manual test steps
without implementing tests or triggering an implementation handoff. Only the
named read operations are allowed through Atlassian MCP.

Both profiles use the `plan-agent` Plannotator workflow and allow `planner` to
call `submit_plan`. Plannotator CLI commands require the `plannotator`
executable supplied by mise.

TypeScript uses built-in language-server discovery. Lua and Nix retain
`lua-language-server` and `nixd` overrides. Built-in formatting remains enabled.

<<<<<<< HEAD
## Repository downloads and RTK

The shared `ghgrab-fetch` skill uses [ghgrab](https://github.com/abhixdd/ghgrab)'s
non-interactive `agent tree` and `agent download` commands. It references the
[video's ghgrab chapter](https://youtu.be/II17TPAb4AQ?t=455) and covers selected
paths, explicit destinations, JSON results, authentication, and release assets.
Chat, explorer, builder, and the personal audit agents can load it. Explorer
can list remote trees; downloads retain its existing shell denial. Other agents
retain their normal shell approval rules. Mise already declares `cargo:ghgrab`.

Both profiles explicitly load a dependency-free OpenCode v2 adapter for
[RTK's OpenCode hook](https://github.com/rtk-ai/rtk/tree/master/hooks/opencode)
through `./plugins/rtk` and their shared `plugins` symlink.
It checks every shell invocation through `rtk rewrite` before execution,
including commands from subagents. RTK owns the rewrite rules: supported commands
use its filters, unsupported commands and explicit `rtk` calls pass through.
Rewrite errors fall back to the original command, with one warning per plugin
instance for an unavailable or broken binary. The rewrite subprocess uses argv,
the invocation's working directory and environment, and a two-second timeout.
Valid rewrites from RTK exit codes 0 and 3 both use OpenCode's normal permission
checks. Codes 1 and 2 with no output leave the original command for OpenCode to
evaluate; the adapter never auto-approves a command from RTK's exit status.

OpenCode evaluates permissions after this hook. Each profile mirrors its ordered
Git/GitHub CLI permission rule to its `rtk` equivalent, including denials such as
`git add -A` and audit-agent commit/push restrictions. Other rewrites retain the
normal ask/deny fallback; there is no blanket `rtk *` allowance. Dedicated read,
grep, and glob tools do not execute a shell and do not pass through RTK.

RTK is already declared in `nix/darwin/homebrew.nix`; `rtk rewrite` requires
version 0.23.0 or newer. This adapter targets OpenCode 2.0.20's
`ctx.shell.hook("create.before", ...)` API, rather than the upstream v1 hook.
Configured local plugins use a package directory for compatibility with 2.0.20.
Do not run `rtk init -g --opencode` over these managed profiles.

After integrating into the active dotfiles checkout, restart OpenCode's service.
`rtk gain` reports savings; `rtk proxy <command>` preserves raw output when needed.

## Activation and verification
=======
## Verification and activation
>>>>>>> main

Use `zsh -n zsh/.zshenv`, pinned V2 schema validation, TypeScript checks, and
offline Nix evaluation for both hosts. Runtime checks should use isolated
temporary data/config directories, disable Atlassian in validation copies, and
never send model requests or use live credentials.

After integrating changes into `~/.dotfiles`, apply the existing nix-darwin
host configuration and restart OpenCode's service separately. This repository
change does not activate Nix or restart services automatically.

`service.json` is machine-local runtime state and remains ignored. Do not copy
it between personal and work profiles.

References: [V2 config](https://opencode.ai/v2/docs/config/),
[migration guide](https://opencode.ai/v2/docs/migrate-v1/),
[agents](https://opencode.ai/v2/docs/agents/),
[permissions](https://opencode.ai/v2/docs/permissions/), and
[V2 plugins](https://opencode.ai/v2/docs/build/plugins/).
