# OpenCode v2 configuration

These profiles target OpenCode 2.0.20. Homebrew manages the executable and
OpenCode self-updating is disabled.

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
files include the Jira, orchestration, and test-plan workflows; all existing
skill directories remain available. V1 tools, archived commands, the old
terminal client configuration, and `prompts/back/` were removed.

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

## Verification and activation

Use `zsh -n zsh/.zshenv`, official-schema validation, TypeScript checks, and
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
