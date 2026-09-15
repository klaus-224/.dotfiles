# OpenCode configuration

Work and personal profiles intentionally have different workflows. Nix manages
the OpenCode executable; both profiles disable application auto-update.

| Profile | Default | Providers | Plugins |
|---|---|---|---|
| `opencode.work.jsonc` | `chat` | GitHub Copilot; Atlassian MCP | None |
| `opencode.personal.jsonc` | `pair-programmer` | OpenAI and OpenCode | Plannotator `0.27.12` |

The shell selects `OPENCODE_CONFIG`; Home Manager links this directory to
`~/.config/opencode`. Relative `{file:...}` references resolve from the profile directory.
No OMO installation or configuration is required. The obsolete OMO registration
and tests have been retired; personal's user-managed Plannotator workflow remains.

## Agents and commands

- Work `chat` can read/search and discuss code, but cannot edit. Shell commands
  require approval. Database exploration is relevant-task-only, authorized, and
  read-only, never a prerequisite for ordinary chat.
- Work `audit-orchestrator` is a primary agent and delegates only to the
  `audit-worker` subagent. The worker cannot delegate further. Their supplied
  prompts and worktree permissions are preserved.
- Work `/summarize-jira-ticket` targets `jira-operator`. Only named Atlassian
  reads and `gh pr list/view/diff` shell calls are exposed and require approval.
  Unknown MCP tool names fail closed until explicitly reviewed.
- Personal `pair-programmer` is read-only and denies shell access. `build` remains
  the explicit implementation agent.
- Personal `planner` and `/test-plan` retain user-managed plan review.
  `/test-plan` targets `orchestrator`, which delegates only to read-only `explorer`
  and `oracle`. Discovery alone runs in parallel, review uses a fresh oracle,
  and at most one correction pass precedes `submit_plan` and stopping.

Profile-specific commands are registered in JSON, with their bodies under
`prompts/`, so work does not advertise personal-only planning agents and personal
does not reference an unavailable Jira agent. Shared Plannotator skill commands
remain under `commands/`; they require their documented local CLI prerequisites.
`prompts/back/` is a preserved archive, not an agent registration directory.
The deleted `agent-defs/` files are not required.

Permissions are guardrails, not a shell sandbox. In particular, do not approve
write operations for read-only roles or use auto-approval to bypass review.
Provider/model availability and MCP authentication require a separate live check.

## Verification without runtime activation

From this directory, with locked development dependencies installed:

```sh
npm test
npm run typecheck
```

Tests parse JSONC, verify file and agent references, check profile-specific
permissions/workflows, and exercise pure custom-tool input parsers.
They do not start OpenCode or install plugins. The SDK dependency is pinned to
`1.18.30`. `npm test` is offline; `npm run test:schema` is an explicit network
check of the current official schema, not a runtime compatibility test.

For dependency provisioning, the manifest selects pnpm and the existing
`pnpm-lock.yaml` passed a frozen install in the audit worktree. The legacy
`package-lock.json` is stale: `npm ci` failed there. Neither lockfile was changed
in this audit; reconcile the redundant npm lock before relying on npm installs.
Running npm test scripts against already provisioned dependencies remains valid.

Do not treat `opencode debug config` as a harmless static parser: loading a
runtime configuration can load plugins, custom tools and MCP configuration.
Only run a resolved-runtime check in an explicitly approved isolated environment.
Current configuration semantics: [agents](https://opencode.ai/docs/agents/),
[permissions](https://opencode.ai/docs/permissions/), and
[commands](https://opencode.ai/docs/commands/).
