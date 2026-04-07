# Global operating rules

- Prefer short responses by default.
- Prefer global dotfiles-managed config over repo-local setup.
- When asked to design agents, optimize for:
  - small prompts
  - clear permissions
  - explicit delegation
  - reusable commands
  - reusable skills
- Do not create giant all-in-one agents when specialized agents are clearer.
- Treat planning, execution, and review as separate concerns unless explicitly told otherwise.
- When editing config, prefer minimal diffs.
- When proposing shell commands, keep them copy-pasteable.
- When uncertain, state the uncertainty plainly.
