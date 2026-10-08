# Configuration

OpenCode targets the pinned 2.0.20 schema. `opencode/opencode.jsonc` is the
single source configuration. Home Manager renders its two provider placeholders
in `nix/home/files.nix`: OpenAI and OpenCode for `klaus224`, GitHub Copilot for
other users. Unlisted providers are denied. Loading the source template directly
does not allow real providers; use the Home Manager configuration.

Home Manager links the shared agents, commands, skills, plugins, preferences,
CLI settings, and editor schema under `~/.config/opencode`. Agent permissions
live in each definition's front matter. Agents inherit the session's selected
model rather than pinning a provider. Jira requires authentication; the browser
MCP remains disabled until configured for an authorized test session.

Run the checks from `opencode/`:

```sh
pnpm test
pnpm test:schema
pnpm test:workflows
pnpm typecheck
```

Schema and workflow fixtures validate both rendered provider allowlists, shared
agent discovery metadata, command skill IDs, and permission boundaries. They
do not authenticate services, run model requests, or exercise saved approvals.

Evaluate both hosts from `nix/` before applying Home Manager changes:

```sh
nix eval --offline .#darwinConfigurations.klaus-macbook.system.drvPath
nix eval --offline .#darwinConfigurations.work-macbook.system.drvPath
```

Apply the existing nix-darwin host configuration after updating the checkout,
then run `opencode service restart`. Changes to the source JSONC require another
Home Manager application; linked Markdown and plugin sources remain shared.
Keep credentials, OAuth sessions, and machine-local `service.json` out of Git.
