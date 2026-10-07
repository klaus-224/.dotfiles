# Migration validation — 2026-10-07

Validated the final workflow requested in the session: default builder, visible
read-only chat, read-only explore/reviewer subagents, and optional Plannotator
planning that returns approved implementation to the same builder.

## Local checks

| Check | Result |
| --- | --- |
| Existing PR context tests (`pnpm test`) | Pass |
| Both profile JSONC files / generated editor schemas (`pnpm test:schema`) | Pass against pinned OpenCode 2.0.20 |
| Workflow fixtures (`pnpm test:workflows`) | Pass; 8 profile checks |
| TypeScript (`pnpm typecheck`) | Pass |
| Zsh environment syntax (`zsh -n zsh/.zshenv`) | Pass |
| Final diff whitespace (`git diff --check`) | Pass |
| Broken managed profile links | None found |
| Published Plannotator 0.27.22 V2 setup with a local mock host | Registers submit_plan in user-managed mode; installs no planning prompt hook |

Workflow fixtures parse Markdown using V2's `gray-matter` parser and decode agent
and command metadata with the pinned schemas. They cover exact skill IDs,
agent selection, profile-only Jira resources, and representative policy outcomes:
read-only edit denials even after a global edit allow, forbidden builder
delegation, routine builder checks, install/external-directory prompts, credential
denials with example-file reads, and direct/RTK Git mutation denials.

These are static policy checks, not runtime shell-scanner or browser/MCP tests.
No destructive operation was executed against real data. The local Plannotator
mock did not open a UI, submit a plan, request a model, or write runtime state.

## Version-specific source inspection

Inspected OpenCode tag `v2.0.20` config agent/discovery/instruction loaders and
permission evaluator. Agent discovery scans `agents/**/*.md` through symlinks;
Markdown supplies system text and appends native permissions. Models remain in
profile JSONC. Global `AGENTS.md` is loaded from the selected config directory.
Configured denials are evaluated before saved approval allows in that source;
session-specific permissions and project overrides still need laptop inspection.

Inspected the published `@plannotator/opencode@0.27.22` package's V2 server export.
`user-managed` registers submit_plan without modifying agent prompts. Approval
uses the selected target agent, checks its availability, and switches the
session/model via the host API. The pinned `@opencode/plugin@2.0.20` types expose
those operations. Builder is the selected target for requested implementation;
planning-only work keeps implementation disabled. Interactive handoff remains
unverified here.

## Checks not performed

The user requested no live workflow testing. No Jira issue, PR comment, browser
test, live model request, or laptop activation was performed as validation.
Actual laptop CLI/service versions, effective project/session overrides, saved
approvals, OAuth sessions, Jira metadata, and MCP/browser tool discovery remain
unverified. Work browser MCP is configured disabled until a test session is
available. Jira tool names are retained from existing config and must be checked
against exposed schemas at invocation. The browser package version exists in the
registry; that is not evidence of authentication or working screenshot capture.

Nix is not installed in this environment; no Nix expressions changed. README
records both existing host evaluation commands and the existing activation path.
Personal/work laptop rollout and real-task adoption remain user-operated steps.
