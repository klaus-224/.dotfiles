# Configuration

OpenCode targets the pinned 2.0.20 schema. `opencode.json` contains shared
provider-neutral settings and agent metadata; `work.jsonc` and `personal.jsonc`
contain provider policies and optional model defaults. Agent Markdown files
supply prompts without frontmatter. Commands and skills retain discovery metadata.

Zsh's `opencode-profile work|personal` installs individual links into the real
`${XDG_CONFIG_HOME:-$HOME/.config}/opencode` directory. It uses `DOTFILES_HOME`
with a `$HOME/.dotfiles` fallback, validates roots and source links before
writing, rejects conflicts, and clears inherited configuration overrides.
Startup defines the function without silently selecting a profile.

The installed skills, commands, and plugins use curated source directories.
Jira/PW originals remain retained, and the previous mixed config lives in
`retained/opencode.jsonc`. Home Manager no longer renders OpenCode placeholders
or manages its files. Package installation is unchanged.

See [activation and verification](../README.md) for one-time Nix activation,
conflict backup, profile switching, pinned schema and workflow checks, and
machine-specific account/model verification.

When Nix is available, evaluate both hosts before applying the configuration:

```sh
nix eval --offline .#darwinConfigurations.klaus-macbook.system.drvPath
nix eval --offline .#darwinConfigurations.work-macbook.system.drvPath
```

Keep credentials, OAuth sessions, runtime service files, and private test
evidence out of Git. Existing sessions retain their selected model; verify
fresh sessions and subagents when updating profile defaults.
