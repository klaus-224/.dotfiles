# Migration baseline — 2026-10-07

Started from clean local `work` at `8665786284d7416ad404d65209f351258e6fae96`.
Created `chore/opencode-workflows`, fetched `origin/main`, and fast-forwarded to
`72c3cee62dc710c0c1a3ae1b8a4cc1c8f6a8622f` before editing. This preserves the
recent Jira bug template and avoids proposing a migration against stale config.
No unrelated local changes were present.

## Observed configuration

- Both profiles and local schema/plugin packages target OpenCode 2.0.20.
- OpenCode CLI/service and Nix are not installed in this cloud checkout. Laptop
  CLI/service versions, effective config, project overrides, and saved approvals
  cannot be inferred here. Do not claim laptop rollout validation.
- Home Manager selects personal for `klaus224`, work for other usernames, and
  links `~/.config/opencode` to `~/.dotfiles/opencode/<profile>`.
- Each profile links `prompts -> ../prompts`, `skills -> ../skills`, and its own
  RTK plugin; personal also links the PR context plugin. No agents/commands links
  existed at baseline.
- Zsh has no `OPENCODE_CONFIG` override. No `OPENCODE*`, `XDG_*`, or `CONTEXT7*`
  variable names are set in this execution environment. Credential values and
  conversation/approval stores were not read.
- Work has Atlassian remote MCP. GitHub reads use `gh`; documentation uses `ctx7`.
  These are configured routes, not proof of authenticated laptop access.

## Keep / migrate / retire

| Resource | Decision |
| --- | --- |
| Existing provider policies and per-profile models | Keep |
| RTK V2 shell adapter and personal PR context plugin | Keep; preserve permission checks |
| Home Manager profile selector, local schemas, cli.json | Keep |
| chat / builder / explorer prompts | Migrate to discovered chat / builder / explore agents; add reviewer |
| PR review research and manual-test-plan skill | Reuse in skills |
| Jira bug interview and exact team template from main | Migrate to jira-bug skill and adjacent references |
| Atlassian MCP | Keep in work; metadata and tool availability checked at invocation |
| Mandatory planner handoff and unconditional code review | Retire |
| planner / ticket-review / pr-review / test-planner / Jira IDs | Retire after skill migration |
| Personal audit agents | Retire active registrations; retain prompt library |
| Built-in plan | Disable; builder owns its optional planning phase, per the user's revised workflow |
| Built-in build | Disable using V2 `disabled`, after discovered builder validation |
| Plannotator package | Keep pinned package at user request; user-managed flow, V2 export/API verified from the package and pinned host API; interactive behavior unverified |
| Oh My OpenAgent | No active package/config found |
| Existing simple-coding, find-docs, ghgrab-fetch and CLI/Plannotator skills | Keep as reusable library |
| Project-local overrides and saved approvals on laptops | Unverified; inspect during activation |

The requested migration targets V2 names (`agents`, `permissions`, `shell`,
`subagent`, `mcp.servers`). Local schema validation does not establish runtime
discovery, login, or saved-approval behavior. No live Jira/browser workflow tests
are performed, per the user's instruction.

## Final workflow decisions

The user revised the attached plan during implementation: builder is the default
primary and optionally plans through Plannotator before resuming its own approved
implementation. Chat also remains visible as a read-only primary. Explore and
reviewer remain read-only subagents. Planning is required only when requested.
These decisions supersede the attachment's chat default and separate plan-agent
handoff. Plannotator uses `user-managed` so it does not inject a mandatory
planning workflow; native permissions expose `submit_plan` only to builder.
