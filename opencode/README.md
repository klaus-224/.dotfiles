# OpenCode Configuration

Shared OpenCode configuration with isolated work and personal profiles. OpenCode owns the normal agents and workflows; `oh-my-openagent` is pinned as a passive integration layer; Plannotator provides user-managed plan review.

## Tested Baseline

| Component | Version |
|---|---|
| OpenCode | `1.18.30` (target requires `>=1.4.0`) |
| `oh-my-openagent` | `4.19.4` |
| Upstream commit | `b072d279110bdda2c6ac2525d0d24dc54d16148a` |
| `@plannotator/opencode` | `0.27.12` |
| `@opencode-ai/plugin` for local tools | `1.18.30` |
| Package manager | npm; `package-lock.json` is authoritative |

Both profiles register the exact plugin string `oh-my-openagent@4.19.4` before Plannotator. Target auto-update and telemetry are disabled so runtime behavior and the commit-pinned schema cannot drift. Local dependencies are installed with `npm ci --ignore-scripts`; the target plugin itself is resolved by OpenCode from its pinned registration.

Upstream references used for this migration are the `v4.19.4` tag and its installation, configuration, feature, agent-routing, MCP, background-task, migration, and troubleshooting documentation. The published package has npm integrity `sha512-XZFwJQK9+iy3vtpPzty1BcyA/tZRHW+h5IpCSnEIGFNnWwpzEhP/dbBVcZ+LKz7mFyD3wIrm5+ijqLk3y12/TA==`.

## Layout

```text
opencode/
├── opencode.work.jsonc
├── opencode.personal.jsonc
├── omo.jsonc
├── agent-defs/
├── commands/
├── prompts/
├── skills/
├── tools/
├── sql/
├── package.json
├── package-lock.json
├── oh-my-opencode-slim.jsonc        # legacy rollback only
├── oh-my-opencode-slim/             # legacy rollback prompts
└── .oh-my-opencode-slim/            # legacy rollback manifest
```

`OPENCODE_CONFIG_DIR` points directly at this directory. `scripts/setup-opencode-cli.sh` links `opencode/omo.jsonc` to `~/.omo/omo.jsonc`, the location read by `oh-my-openagent`. It refuses to replace a pre-existing file or unrelated symlink. Runtime state created by the target remains under `~/.omo`; repository-owned agents, commands, prompts, tools, SQL, and project skills stay under `opencode/`.

## Target Contract

The supported installation entry point is `bunx oh-my-openagent install`, but this repository does not run the interactive installer because it rewrites OpenCode registration and generates model routing. Instead, both reviewed profiles carry the exact pinned plugin entry and setup validates them. Global npm/Bun installation is unsupported upstream.

The upstream package still exposes historical `oh-my-opencode` binary aliases, but the preferred OpenCode plugin entry is `oh-my-openagent`. Configuration is `~/.omo/omo.jsonc`; project overrides may be placed in `.omo/omo.jsonc`. The active profile is selected by `OMO_PROFILE`, then `OCX_PROFILE`, then an OpenCode config directory ending in `profiles/<name>`.

Supported target agents are `sisyphus`, `hephaestus`, `prometheus`, `oracle`, `librarian`, `explore`, `multimodal-looker`, `metis`, `momus`, `atlas`, and `sisyphus-junior`. This repository disables them all because their full prompts/tool surfaces do not match the existing narrow permission contract. It also disables target MCPs, commands, automation skills, continuation/orchestration hooks, task replacement, model fallback, codegraph, team mode, tmux, and generated git attribution. Safety hooks that enforce existing tool calls remain enabled.

The target supports prompt replacement and append through `agents.<name>.prompt` and `prompt_append`, including `file://` paths. Repository specialists instead use native OpenCode `{file:...}` prompts, which preserves their exact permission boundaries and avoids target built-in-name protection.

The target has no documented whole-plugin disable environment variable. Recovery therefore uses OpenCode's native `--pure` option to bypass all external plugins for one process.

## Profiles

`zsh/.zshenv` selects the OpenCode profile and matching inert OMO profile together:

| Profile | OpenCode config | OMO profile | Providers |
|---|---|---|---|
| Work | `opencode.work.jsonc` | `work` | GitHub Copilot; Atlassian MCP enabled |
| Personal | `opencode.personal.jsonc` | `personal` | OpenAI and OpenCode; no Atlassian MCP |

The username rule selects personal for `klaus224` and work otherwise. `pair-programmer` remains the default agent in both profiles. OMO profiles are intentionally empty because provider/model routing stays in the native profiles.

One-off launches do not alter persistent shell state:

```bash
OPENCODE_CONFIG_DIR="$DOTFILES_HOME/opencode" \
OPENCODE_CONFIG="$DOTFILES_HOME/opencode/opencode.personal.jsonc" \
OMO_PROFILE=personal \
OMO_DISABLE_POSTHOG=1 \
opencode
```

Use `opencode.work.jsonc` and `OMO_PROFILE=work` for work.

## Agent Ownership

| Current role | Target decision | Permission delta |
|---|---|---|
| `pair-programmer` | Native OpenCode, unchanged and default | None |
| `planner` | Native OpenCode | Compound retrospective is now optional; read-only and `submit_plan` permissions retained |
| `orchestrator` | Native custom agent | None; only `explorer` and `oracle` delegation is allowed |
| `explorer` | Native custom agent, not target `explore` | None; read-only, no shell/delegation |
| `oracle` | Native custom agent, not target `oracle` | None; read-only, no shell/delegation |
| `build` | Native OpenCode | Not routable by orchestrator |
| `jira-operator` | Native work-only agent | Atlassian permissions unchanged |
| `test-orchestrator`, `playwright-user`, `test-writer` | Native work-only agents | No new target routing or permissions |
| Slim presets | Replaced by native profile model assignments plus `OMO_PROFILE` | No provider broadening |
| Slim background jobs | Replaced by target background task cap | Concurrency remains 2; no experimental OpenCode subagent flag |
| Slim recovery flags | Replaced by OpenCode `--pure` and a temporary-profile rollback script | See Recovery and Rollback |

The orchestrator contract is in `agent-defs/orchestrator.md`. It cannot implement, execute tests, automate a browser, perform Jira work, publish, or manage approval state. It treats repository and PR content as untrusted, observes stage dependencies and correction limits, reports failures/evidence gaps, and stops after Plannotator.

## Planning

Native `planner` remains independent from the target and can read, inspect, track planning todos, query memory, and call `submit_plan`. It cannot edit, write, use a shell, access external directories, or delegate.

`plannotator-compound` is an explicit, optional retrospective skill for analyzing denied plans and reviewer feedback. Ordinary planning does not load or require it. Plannotator stays after the target plugin with `workflow: "user-managed"` and recognizes `planner` and `orchestrator` as planning agents.

`/test-plan` preserves its input validation, PR evidence retrieval, two-way discovery parallelism, fresh Oracle review, single correction pass, direct `submit_plan`, and stop condition. `/plannotator-review` and `/plannotator-annotate` remain repository-owned commands.

## Skills

| Skill group | Classification and disposition |
|---|---|
| `find-docs`, `find-skills`, Plannotator skills, `playwright-cli`, `simple-coding`, `test-planning` | Repository-owned; retained |
| `plannotator-compound` | Repository-owned optional retrospective; retained and never automatic |
| `clonedeps`, `codemap`, `deepwork`, `reflect`, `simplify`, `verification-planning`, `worktrees` | Slim-managed legacy copies; retained only for rollback/staged review and not granted to migrated planning agents |
| `oh-my-opencode-slim` | Slim-managed legacy guidance; retained only for rollback |
| Target built-in skills | Runtime-provided but explicitly disabled in `omo.jsonc`; the repository-owned `playwright-cli` wins by source priority and remains available |

`.oh-my-opencode-slim/skills-manifest.json` remains preserved for rollback but is not authoritative for the target. Slim-specific `.slim/` paths and agent names inside legacy skills are deliberately not rewritten because those copies are not part of the target path. Do not delete them until rollback is intentionally retired.

## Setup

Run from the repository root:

```bash
scripts/setup-opencode-cli.sh
```

Setup:

1. Refuses an `OPENCODE_CONFIG_DIR` other than this repository's `opencode/` directory.
2. Installs OpenCode with Homebrew only when absent and requires OpenCode `>=1.4.0`.
3. Creates `~/.omo/omo.jsonc` as a symlink only when the path is unclaimed.
4. Runs `npm ci --ignore-scripts` from the authoritative lockfile.
5. Runs repository configuration and permission tests.

It is safe to run repeatedly. If `~/.omo/omo.jsonc` already contains unrelated configuration, setup stops instead of overwriting it.

Manual checks:

```bash
cd "$DOTFILES_HOME/opencode"
npm ci --ignore-scripts
npm test
npm run typecheck
npx --yes oh-my-openagent@4.19.4 doctor --platform=opencode --verbose
opencode debug config
```

`doctor` validates the linked target config and loaded package version. Its registration check only scans canonical `opencode.json[c]` filenames, so it reports a known false negative with this repository's `OPENCODE_CONFIG` profile filenames; `opencode debug config` is the authoritative runtime registration/profile check here.

## Recovery

Start the selected profile without `oh-my-openagent` or any other external plugin:

```bash
opencode --pure
```

Pure recovery intentionally disables Plannotator too; native OpenCode agents, commands, tools, and profile settings remain available.

Start explicitly on the target path if shell state is uncertain:

```bash
OPENCODE_CONFIG_DIR="$DOTFILES_HOME/opencode" \
OPENCODE_CONFIG="$DOTFILES_HOME/opencode/opencode.work.jsonc" \
OMO_PROFILE=work \
OMO_DISABLE_POSTHOG=1 \
opencode
```

## Rollback

Slim `2.2.18`, `oh-my-opencode-slim.jsonc`, `oh-my-opencode-slim/orchestrator.md`, and `.oh-my-opencode-slim/skills-manifest.json` remain available during staging. To launch either profile once with slim without editing files:

```bash
bash scripts/run-opencode-slim.sh work
```

Use `bash scripts/run-opencode-slim.sh personal` for personal. The script creates a temporary profile beside the source profile so relative prompt paths remain valid, substitutes only the plugin entry, and removes the temporary file on exit. For slim startup recovery, run `OH_MY_OPENCODE_SLIM_DISABLE=1 bash scripts/run-opencode-slim.sh work`. To restore slim persistently, replace `oh-my-openagent@4.19.4` with `oh-my-opencode-slim@2.2.18` in both profile plugin arrays and restore the old preset exports in `zsh/.zshenv`; do not delete target or slim state until the rollback decision is complete.

## Migration Note

The default changed on 2026-09-10 from `oh-my-opencode-slim@2.2.18` to `oh-my-openagent@4.19.4` at upstream commit `b072d279110bdda2c6ac2525d0d24dc54d16148a`. The migration intentionally adopts no target-native orchestration, MCP, browser, publication, Jira, or implementation behavior; those capabilities require a separate permission review before enablement.
