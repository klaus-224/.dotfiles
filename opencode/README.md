# OpenCode profiles

These profiles target OpenCode 2.0.20. Homebrew manages the executable and
OpenCode self-updating is disabled. The local editor schemas are generated from
`@opencode/schema@2.0.20` with `pnpm schema:generate`.

## Edit sources, then generate

OpenCode 2.0.20 has no configuration `extends` field. A small offline generator
composes the shared library and each profile's explicit selections into native
OpenCode configuration:

```text
opencode/
  config/
    shared.jsonc       Common settings and reusable agent definitions/permissions
    personal.jsonc     Personal selections, models, settings, commands, and skills
    work.jsonc         Jira/Playwright selections and Copilot models
  agents/
    *.md               Agent system instructions
    archive/           Inactive agent instructions, never selected automatically
  commands/
    jira-test-plan.md   Work /test-plan command template
    jira-bug.md         Work /bug command template
    archive/           Inactive PR-test-plan and Jira-summary command templates
  skills/              Canonical skill library
  personal/            Generated opencode.jsonc, cli.json, selected skill links/plugins
  work/                Generated opencode.jsonc, cli.json, selected skill links/plugins
```

Edit `config/shared.jsonc` to change a reusable agent or a common setting. Select
that agent in `config/personal.jsonc` or `config/work.jsonc`, with its model and any
profile-specific overrides. An agent's presence in the shared library does not
activate it. Edit its Markdown in `agents/`; command templates belong in `commands/`.

Run from this directory:

```sh
pnpm config:generate
pnpm config:check
pnpm test
pnpm typecheck
```

Both generated `opencode.jsonc` files and the profile skill symlinks are committed.
Do not edit generated files directly. Regenerate after changing agent or command
Markdown as well as configuration sources. `cli.json` remains hand-edited per
profile, and schema regeneration is separate.

Composition is explicit: profile settings replace shared settings at the top
level; plugin lists append in shared-then-profile order; only selected agents
are included. Agent overrides replace entire fields, including ordered permission
arrays. Commands are selected per profile and must target a selected agent.

The generator embeds selected Markdown as native `system` and `template` strings.
It does not expose the whole agent/command library to runtime directory discovery,
so archived and personal-only definitions cannot leak into the work profile.
Skill directories contain only links selected by each profile. Generation removes
unselected skill symlinks but refuses to delete unexpected real files/directories.

## Profile scope

| Profile | Default | Active custom agents | Providers |
| --- | --- | --- | --- |
| Personal | `chat` | `chat`, `planner`, `explorer`, `builder`, `audit-orchestrator`, `audit-worker` | OpenAI, OpenCode |
| Work | `ticket-review` | `ticket-review`, `pr-review`, `test-planner`, `Jira`, `playwright-user`, `pw-test-writer` | GitHub Copilot |

Personal retains its existing planning/building, audit, Plannotator, local
references, Lua/Nix LSP overrides, and PR-context plugin. Its planner alone can
use `pr_context_get`. The inactive PR test-plan command still depends on an
unregistered oracle workflow and remains archived.

Work contains only Jira and Playwright workflows plus their supporting research
and PR inspection. General built-in `general`, `build`, and `plan` agents are
**disabled**, not merely hidden. Personal references, Lua/Nix overrides, general
chat/planning/building agents, audit agents, and Plannotator are not included.
Work exposes only `find-docs`, `manual-test-plan`, and `playwright-cli` skills.

- `/test-plan <Jira key or URL>`: `ticket-review` retrieves Jira requirements,
  delegates implementation analysis to `pr-review`, and forwards the completed
  evidence to `test-planner`. It returns manual test steps without running them.
- `Jira`: Jira and linked-PR summaries, plus `/bug` creation through the existing
  Plannotator form and review gate. The exact reviewed bug is created only after
  approval. Existing issues, comments, and transitions are not modified. This
  workflow uses the mise-managed Plannotator CLI, not the OpenCode plan plugin.
- `playwright-user`: browser-based verification using Playwright CLI, with an
  explicit environment and an approved test plan. It consumes Jira evidence from
  `/test-plan`; it does not update Jira or edit application code.
- `pw-test-writer`: writes and verifies Playwright tests, fixtures, and page objects.
  Shell execution and file edits require approval; it does not implement app changes.

Playwright CLI is declared in `mise/config.toml`. Browser binaries, test-project
dependencies, and authentication state still follow each repository's setup.
Model availability and Jira access depend on the connected account; offline
validation does not authenticate or send model requests.

## Runtime selection and plugins

Home Manager links `~/.config/opencode` to `personal` for `klaus224` and `work` for
other users, via `nix/home/files.nix`. Zsh does not override the config path.
Generation preserves these runtime paths and requires no Nix selector changes.

Both profiles load `./plugins/rtk`. This dependency-free V2 adapter uses
`ctx.shell.hook("create.before", ...)` and `rtk rewrite` with a two-second timeout.
Unsupported commands and failures fall back to the original command. Rewrites
still undergo OpenCode's permission checks; there is no blanket `rtk *` allowance.
RTK is installed by Homebrew and requires 0.23.0 or newer. Do not run
`rtk init -g --opencode` over these managed profiles. Use `rtk gain` for savings.

Personal additionally loads `./plugins/pr-context` and
`@plannotator/opencode@0.27.22`. Its `planner` uses `submit_plan`; select `builder`
as the implementation agent in Plannotator when handing off an approved plan.
The Plannotator CLI is supplied by mise.

After generating and syncing these dotfiles to a machine, run
`opencode service restart` to reload the profile. Apply the existing nix-darwin
configuration if the Home Manager link has not yet been installed. No activation
or service restart is performed by the generator.

`service.json` is ignored machine-local runtime state. Never copy it between
profiles. For runtime smoke checks, use isolated temporary data/config directories,
disable Atlassian in validation copies, and avoid live credentials/model requests.

References: [V2 config](https://opencode.ai/v2/docs/config/),
[agents](https://opencode.ai/v2/docs/agents/),
[permissions](https://opencode.ai/v2/docs/permissions/), and
[V2 plugins](https://opencode.ai/v2/docs/build/plugins/).
