# OpenCode v2 configuration

The active layout targets OpenCode 2.0.20. Homebrew still installs the executable;
application self-updating remains disabled. Zsh owns configuration links and
profile selection. Home Manager owns neither.

| Source under `~/.dotfiles/opencode` | Installed entry | Purpose |
| --- | --- | --- |
| `opencode.json` | `opencode.json` | Shared agent metadata, permissions, plugins, and general settings |
| `work.jsonc` or `personal.jsonc` | `opencode.jsonc` | Selected provider policy and model defaults |
| `agents/` | `agents/` | Shared Markdown system prompts, without configuration frontmatter |
| `shared-commands/` | `commands/` | Curated links to the shared command templates |
| `shared-skills/` | `skills/` | Curated links to the existing shared skill libraries |
| `shared-plugins/` | `plugins/` | Curated v2 RTK and PR context plugins |
| `cli.json` | `cli.json` | Shared v2 terminal settings |
| `AGENTS.md` | `AGENTS.md` | Shared working preferences |
| `opencode.schema.json` | `opencode.schema.json` | Editor schema generated from `@opencode/schema@2.0.20` |

The destination `${XDG_CONFIG_HOME:-$HOME/.config}/opencode` is a real directory.
Its managed entries link into the canonical dotfiles source. Credentials,
service configuration, databases, and unrelated entries stay machine-local.

## Profiles and shared agents

`work.jsonc` allows only `github-copilot`. Its root default, builder, and reviewer
use `github-copilot/gpt-6.1-sol`; chat uses `github-copilot/claude-sonnet-5.5`,
and explore uses `github-copilot/claude-haiku-5.5`.

`personal.jsonc` allows exactly `opencode` and `openai`. It leaves model defaults
unset until availability is confirmed with the model picker on the personal
machine. Then add a verified root `model` and optional `agents.<id>.model`
overrides to that file. Existing sessions retain their selected models;
validate new sessions and subagents when changing defaults. Policies restrict
providers; they do not authenticate an account.

Builder remains the default primary agent. Chat provides read-only discussion;
explore performs bounded research, and reviewer provides independent review.
The [Claude-style harness](docs/claude-harness.md) adds persistent task checkpoints,
compaction guidance, bounded retries, repeated-failure handling, and a `worker`
subagent for bounded implementation. Builder keeps responsibility for integration
and verification. It runs inside OpenCode with either existing provider profile.
The latest shared Markdown bodies are preserved completely in `agents/`, with
configuration frontmatter removed. Descriptions, modes, ordered provider-neutral
permission rules, and built-in overrides now live in `opencode.json`. JSON agent
definitions omit `system` so Markdown discovery supplies it. Credential gates,
read-only agent restrictions, and Git safety rules remain effective. The shared
terminal settings are preserved from the current `cli.json`.

The shared Plannotator package remains `@plannotator/opencode@0.27.22`, with its
current `user-managed` workflow. `/build-plan` prepares an optional plan for
builder; `/plannotator-review`, `/plannotator-annotate`, and `/plannotator-last`
provide their existing shared workflows. The new writing skill and its HTML
and diagram helpers remain available. Skill frontmatter and command templates
are preserved.

The v2 RTK adapter rewrites shell commands before normal permission checks,
retaining the existing ordered Git/RTK restrictions. No blanket RTK allow is
added. `rtk rewrite` requires RTK 0.23.0 or newer. Do not run
`rtk init -g --opencode` over this configuration. `shared-plugins/` includes the
v2 package adapters and omits the retained legacy `plugins/rtk.ts`; TypeScript
checks exclude that inactive v1 file.

## Excluded assets are retained

Jira, Atlassian MCP, work test-plan commands, Playwright skills, and related
permissions are absent from the installed configuration. Original command and
skill files remain untouched in `commands/` and `skills/`; relocation into a
work repository is separate work. Curated directories omit `jira-ticket`,
`jira-bug`, `playwright`, `playwright-cli`, `manual-test-plan`, `manual-testing`,
and `test-planning`, along with commands that depend on them. The previous mixed
configuration is retained intact as `retained/opencode.jsonc`, outside automatic
configuration discovery. Shared prompt bodies retain their complete wording;
work-specific workflows require definitions supplied by the work repository.

The old personal/work directory profiles were already retired on `main`.
No obsolete planner, explorer, or audit agent is reintroduced by this migration.
Do not install separate profile directories.

## One-time activation

First apply the normal nix-darwin configuration once to release Home Manager's
old whole-directory link. Choose the command for the machine:

```sh
sudo darwin-rebuild switch --flake ~/.dotfiles/nix#work-macbook
# Personal machine: use ~/.dotfiles/nix#klaus-macbook instead.
```

Open a fresh zsh session after activation, or source the new function explicitly:

```zsh
source "${DOTFILES_HOME:-$HOME/.dotfiles}/zsh/.zshrc.d/opencode-profile.zsh"
```

Inspect the destination before setup. If the old whole-directory link remains,
move the link itself to a unique backup name; do not follow it or write inside
its target:

```zsh
opencode_destination="${XDG_CONFIG_HOME:-$HOME/.config}/opencode"
if [[ -L "$opencode_destination" ]]; then
  opencode_backup="${opencode_destination}.before-zsh-$(date +%Y%m%d-%H%M%S)"
  [[ ! -e "$opencode_backup" && ! -L "$opencode_backup" ]] || return 1
  mv "$opencode_destination" "$opencode_backup"
fi
opencode-profile work
# Or: opencode-profile personal
opencode service restart
```

The function refuses to overwrite regular files or directories. If it reports
an entry conflict, inspect and move that entry to a unique backup outside the
managed destination, then retry. Preserve application-managed entries. A root
symlink is always rejected by the function; backup is a deliberate one-time
operation after Nix activation.

Profile selection persists through the `opencode.jsonc` link. Startup only
defines the function; it does not choose or change a profile:

```zsh
opencode-profile work
opencode-profile personal
```

The function uses `DOTFILES_HOME`, falling back to `$HOME/.dotfiles`, and the
existing Node runtime to strictly resolve links on macOS and Linux. It rejects
symlinked source roots and managed source entries, overlapping canonical roots,
nested links escaping the source (including intermediate hops), dangling links,
resolution loops, directory cycles, and regular destination conflicts before
writing. It leaves identical shared links in place, verifies all links after
installation, and unsets `OPENCODE_CONFIG` and `OPENCODE_CONFIG_CONTENT` in the
calling shell after success. No obsolete configuration exports were found in
the repository's startup or mise files. `OPENCODE_SESH_DB` remains unrelated
session tooling configuration.

## Repository builder permissions

Use the same builder ID in a repository's `.opencode/opencode.jsonc`:

```json
{
  "$schema": "https://opencode.ai/config.json",
  "agents": {
    "builder": {
      "permissions": [
        { "action": "shell", "resource": "pnpm test *", "effect": "allow" }
      ]
    }
  }
}
```

Permission arrays append while omitted metadata and the shared Markdown prompt
remain inherited. Ordinary rules use the last match; avoid late blanket allows.
Use global `experimental.policies` with action `permission` for prohibitions
that repository rules must never relax. Provider policies stay exclusively in
the profile files.

## Verification

From `opencode/`, run:

```sh
pnpm test:schema
pnpm test:profiles
pnpm test:workflows
pnpm test
pnpm typecheck
```

Also check zsh syntax from the repository root:

```sh
zsh -n zsh/.zshenv
zsh -n zsh/.zshrc
zsh -n zsh/.zshrc.d/opencode-profile.zsh
```

The existing generated 2.0.20 schema from the earlier profiles is retained
unchanged at the root. Regenerate it only when the pinned schema package changes. The profile-switch
suite exercises switching, unrelated state preservation, whole-directory
links, aliases and overlaps, escaping and cyclic source links, dangling links,
regular conflicts, and inherited override removal using isolated fixtures.

OpenCode 2.0.20 runtime checks used isolated XDG config/data/cache/state and npm
cache directories with model catalog fetching disabled and no account credentials.
They confirmed both recognized config files load, all shared Markdown prompts
are discovered, both profiles share skills/plugins, and a repository builder
allow appends while an unrelated shared deny remains effective. The shared
`cli.json` validated against the CLI schema from the 2.0.20 source.

On each actual machine, complete Nix activation, restart the service, confirm
Copilot-only work and OpenCode/OpenAI-only personal availability with `opencode
models`, select a verified personal default, and check fresh sessions. Nix tools
and authenticated Copilot/OpenAI accounts were unavailable in the Linux test
workspace. No model requests were sent.

References: [v2 configuration](https://opencode.ai/v2/docs/config),
[2.0.20 loader](https://github.com/anomalyco/opencode/blob/v2.0.20/packages/core/src/config.ts),
[agents](https://opencode.ai/v2/docs/agents),
[skills](https://opencode.ai/v2/docs/skills),
[permissions](https://opencode.ai/v2/docs/permissions),
and [policies](https://opencode.ai/v2/docs/policies).
