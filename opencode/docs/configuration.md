# Configuration

This configuration targets OpenCode 2.0.20.

## Files and profiles

| Source | Purpose |
| --- | --- |
| `opencode.json` | Shared settings and agent metadata, independent of provider |
| `work.jsonc`, `personal.jsonc` | Provider rules and optional default models |
| Agent Markdown files | Prompts, without frontmatter |
| Commands and skills | Definitions with discovery metadata |

Select a profile with `opencode-profile work` or `opencode-profile personal` in
zsh. The function links individual entries into the real directory at
`${XDG_CONFIG_HOME:-$HOME/.config}/opencode`.

It uses `DOTFILES_HOME`, falling back to `$HOME/.dotfiles`. Before writing, it
validates source roots and links and rejects conflicts. After success, it clears
inherited configuration overrides. Shell startup defines the function but does
not select a profile.

Skills, commands, and plugins come from curated source directories. The original
Jira and Playwright assets remain in the repository. The previous mixed
configuration is kept in `retained/opencode.jsonc`.

Home Manager does not manage OpenCode files or render placeholders. Package
installation is unchanged.

## Setup and checks

See the [setup guide](../README.md) for one-time Nix activation, conflict backups,
profile switching, validation checks, and account and model checks on each machine.

When Nix is available, evaluate both hosts before applying the configuration:

```sh
nix eval --offline .#darwinConfigurations.klaus-macbook.system.drvPath
nix eval --offline .#darwinConfigurations.work-macbook.system.drvPath
```

Existing sessions keep their selected model. After changing profile defaults,
check fresh sessions and subagents.

Keep credentials, OAuth sessions, runtime service files, and private test evidence
out of Git.
