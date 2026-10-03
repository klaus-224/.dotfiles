# OpenCode v2 configuration

These profiles target OpenCode 2.0.20. Homebrew manages the executable; OpenCode
self-updating is disabled.

| Profile | Machine user | Providers | Additional agents |
| --- | --- | --- | --- |
| `personal/opencode.jsonc` | `klaus224` | OpenAI, OpenCode | `audit-orchestrator`, `audit-worker` |
| `work/opencode.jsonc` | `rohineshram` | GitHub Copilot | `ticket-review`, `pr-review`, `test-planner`, `jira-operator` |

Both start with `chat` and include `planner`, `explorer`, and `builder`. Models
and variants remain profile-specific. Availability depends on your provider
account; configuration validation does not authenticate or run a model.

## Loading and shared files

Home Manager links `~/.config/opencode` to the selected profile directory. Zsh
sets `OPENCODE_CONFIG_DIR` to the same directory and clears the old
`OPENCODE_CONFIG` file override. This avoids merging personal configuration into
work configuration. As before, users other than `klaus224` select work.

Each profile links `prompts`, `skills`, and `cli.json` to shared files. File
references resolve from the profile directory, including when reached through
Home Manager's symlink. Agent registrations live only in profile JSONC. Prompt
Markdown and `prompts/back/` are not auto-discovered agents.

The four legacy custom tools remain under `tools/` and are inactive. Their v1
SDK manifest, lockfiles, and historical tests remain for a future migration.
`command-archive/` preserves old Plannotator command bodies; the v2 plugin
registers the active commands. The Jira template lives under `prompts/` and is
registered only as work's `/test-plan`.

`cli.json` is the active v2 terminal configuration. `tui.json` is a historical
v1 file and is not linked into either active profile.

## Workflows and permissions

Permissions use v2 ordered rules: broad defaults precede specific exceptions,
and the last matching rule wins. Shell and delegation actions are `shell` and
`subagent`. Planning and review agents retain their read-only restrictions.
Delegated workers are discoverable subagents; `hidden` would remove them from
v2's delegation catalog. The original built-in build/plan/general agents remain
hidden in favor of the configured roles.

Work's `/test-plan` retrieves Jira requirements, delegates PR inspection to
`pr-review`, and passes its findings to `test-planner`. It returns manual test
steps without implementing tests or triggering an implementation handoff.
Only the named read operations are allowed through Atlassian MCP; unknown tool
names require a configuration update. Code Mode is enabled for the two Jira
readers so they can access MCP tools; nested calls retain their own permissions.

Both profiles pin `@plannotator/opencode@0.27.22`, use `plan-agent` workflow,
and allow `planner` to call `submit_plan`. In the approval UI, select `builder`
as the destination. Plannotator switches the session to that agent on approval;
rejected plans remain with the planner. The builder keeps its existing approved
plan, commit, and review instructions. Approval does not trigger a separate
synthetic model request. Plannotator CLI commands additionally require the
`plannotator` executable supplied by mise.

TypeScript uses built-in language-server discovery, not `tsc --no-emit`.
Lua and Nix retain `lua-language-server` and `nixd` overrides. These executables
must be available on PATH. Built-in formatting remains enabled.

## Repository downloads and RTK

The shared `ghgrab-fetch` skill uses [ghgrab](https://github.com/abhixdd/ghgrab)'s
non-interactive `agent tree` and `agent download` commands. It references the
[video's ghgrab chapter](https://youtu.be/II17TPAb4AQ?t=455) and covers selected
paths, explicit destinations, JSON results, authentication, and release assets.
Chat, explorer, builder, and the personal audit agents can load it. Explorer
can list remote trees; downloads retain its existing shell denial. Other agents
retain their normal shell approval rules. Mise already declares `cargo:ghgrab`.

Both profiles explicitly load `../plugins/rtk`, a dependency-free OpenCode v2
adapter for [RTK's OpenCode hook](https://github.com/rtk-ai/rtk/tree/master/hooks/opencode).
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

After integrating these changes into `~/.dotfiles`, apply the appropriate
existing nix-darwin host configuration (`klaus-macbook` or `work-macbook`), open a
new shell, then restart OpenCode's service. This repair does not activate Nix or
restart your live service automatically.

`service.json` is machine-local runtime state and must not be tracked. Preserve
any existing local copy privately before applying its repository deletion;
retain it in the selected profile directory if keeping the same service
credentials. Do not copy it between work and personal machines. The active
profile directories ignore generated service metadata.

Use `zsh -n zsh/.zshenv`, evaluate both Nix host configurations without activation,
and inspect each profile with OpenCode v2 in isolated temporary data/config
folders. Check resolved prompts, agent permissions, commands, skills, and plugin
activation. Runtime inspection can load plugins and connect MCP servers: disable
Atlassian in validation copies and use temporary data directories without
credentials. Do not use `debug config` as a purely static JSON parser.

Verified with OpenCode 2.0.20: both Nix host evaluations, shell profile selection,
all prompt references, shared-directory symlinks, effective agent permissions,
profile-specific commands, and activation of the published Plannotator package.
Disposable sessions switched from `planner` to `builder` through the same host
API used by the plugin. Browser approval, live model/Jira authentication, and
language-server connections were not exercised. No model requests were sent.

No tests were added or updated for this repair. Existing tests describe obsolete
v1 filenames and workflows; they are not a v2 acceptance check. Do not install
the legacy custom-tool dependencies merely to validate the active profiles.

References: [v2 config](https://opencode.ai/v2/docs/config/),
[agents](https://opencode.ai/v2/docs/agents/),
[permissions](https://opencode.ai/v2/docs/permissions/), and
[Plannotator](https://github.com/backnotprop/plannotator/tree/main/apps/opencode-plugin).
