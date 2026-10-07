# OpenCode workflows

Profiles target **OpenCode 2.0.20**. Homebrew manages the executable and automatic
self-updating is disabled. Existing providers, models, RTK and personal PR context
remain unchanged. Editor schemas come from pinned `@opencode/schema@2.0.20`; run
`pnpm schema:generate` only after intentionally changing that pin.

## Agents and optional planning

Fresh sessions start on **builder**, which owns implementation and completion.
**Chat** remains visible for read-only discussion; select it in the agent picker
when you want investigation without edits. Explore and reviewer are subagents.
Built-in build and plan are disabled, so there is one implementation owner.
Changing a default does not replace the agent stored on an existing session.

| Agent | Mode | Purpose |
| --- | --- | --- |
| builder | primary, default | Answer questions, implement, verify, capture evidence, finish |
| chat | primary, visible | Discuss and inspect without edits; launch only explore |
| explore | subagent | Bounded repository/documentation investigation; no delegation |
| reviewer | subagent | Optional correctness/coverage review; no edits or execution |

Direct builder requests work without prior planning approval. For a requested
Plannotator planning phase, use `/build-plan <outcome>` or ask builder to plan in
Plannotator first. Builder loads `implementation-plan`, stays read-only while
planning, submits the plan, applies feedback, and then resumes its own approved
implementation. In Plannotator select **builder** as the approval target to retain
that agent and its model. A planning-only request never starts implementation;
leave the approval target disabled and state that you only want the plan.

`@plannotator/opencode@0.27.22` stays enabled with **user-managed** workflow mode.
It registers `submit_plan` without adding mandatory planning prompts; native
permissions allow that tool only on builder. Do not add builder to `planningAgents`:
the plugin considers those agents planning-only and does not request implementation
on their approval. The published V2 server export and pinned host API support
agent/model selection; an unavailable switch or review must be reported as a
blocker, not treated as permission to edit. Interactive behavior is not validated
in this migration.

Plannotator code review remains explicit: `/plannotator-review`,
`/plannotator-annotate`, and `/plannotator-last`. Native plugin commands take
precedence when the host supports them; the managed Markdown commands provide
skill-based CLI fallbacks. Plannotator CLI comes from mise.

## Profile selection and discovery

| Profile | Machine user | Provider policy | Integrations |
| --- | --- | --- | --- |
| personal | klaus224 | OpenAI, OpenCode | RTK, PR context, Plannotator |
| work | other users, including rohineshram | GitHub Copilot | RTK, Plannotator, Atlassian, optional Playwright MCP |

Home Manager in `nix/home/files.nix` selects the profile by username and links
`~/.config/opencode` to `~/.dotfiles/opencode/<profile>`. This remains the single
selector; there is no new root runtime config or shell config override. Each
profile owns `opencode.jsonc`, `cli.json`, and its plugin directory.

Both profiles link `agents`, `AGENTS.md`, and the shared skill/command library into
OpenCode's discovered directories. Work uses individual links for shared skills
and commands plus its own Jira resources. The personal profile does not discover
Jira skills, company bug templates, `/bug`, or the Atlassian/browser server config.
The old prompts library is not auto-loaded; retired planner/explorer and workflow
prompts have been removed. Remaining audit/back prompts are inactive references.

V2 merges discovered agents' frontmatter and body with profile config: models and
permissions are profile-specific, shared agent bodies contain no model override.
Global preferences load from the linked `AGENTS.md`, repository conventions from
project `AGENTS.md`. The accepted `instructions` config array does not load files.
Project configuration and `.opencode/` can override global settings; inspect them
when behavior differs from these profiles. New projects should keep fixtures,
test commands, environment conventions and local templates in their own scope.

## Commands and results

Commands are thin skill entry points with `$ARGUMENTS`; they contain no shell
substitutions. Natural-language requests can load the same exact skill IDs.

| Command | Agent | Skills | Result |
| --- | --- | --- | --- |
| `/build-plan <outcome>` | builder | implementation-plan | Plannotator plan, then builder's own approved implementation |
| `/manual-test-plan <ticket-or-context>` | builder | jira-ticket in work, pr-review, manual-test-plan | AC-linked manual cases; no execution; session output unless a file is requested |
| `/bug <context>` (work only) | builder | jira-bug | Completed team-template draft, then issue link after authorized creation |
| `/manual-test <plan-or-ticket> <environment>` | builder | manual-testing | Per-case PASS/FAIL/BLOCKED and actual evidence; failure bug drafts |
| `/pw-test <ticket-or-scope>` | builder | jira-ticket when available, playwright | Added tests, targeted execution, explicit gaps |
| `/pw-review <PR-or-diff>` | reviewer | pr-review, playwright | Prioritized correctness, coverage, isolation and flakiness findings |

Work `/test-plan` remains a compatibility alias for `/manual-test-plan`.
For personal Jira inputs, report unavailable work tools; use supplied requirements
without claiming ticket retrieval. Chat can produce an in-session manual plan or
review in natural language; commands that may write artifacts select builder.

Examples:

```text
Fix the failing formatter check using existing project conventions.
/build-plan Simplify this repository's config loader, then implement it
/manual-test-plan ABC-123
/bug Checkout fails after selecting an expired payment method
/manual-test work/plans/ABC-123.md https://<authorized-test-environment>
/pw-test ABC-123
/pw-review https://github.com/<owner>/<repo>/pull/<number>
```

Skills return requirements, reviewed PR base/head SHAs, completeness, cases,
expected/actual observations and blockers as appropriate. Missing or inaccessible
PRs produce incomplete evidence, never invented behavior. A blocked browser test
stays BLOCKED; review does not imply tests ran. Bug creation preserves the existing
Plannotator interview and exact team headings, now under work `jira-bug` references
and templates. Prepare a concrete draft before seeking creation authorization;
existing explicit authorization for that exact action remains valid.

## Permissions and required access

V2 ordered rules use `permissions`, `shell`, `subagent`, and `mcp.servers`.
Global rules deny by default; each agent has its own policy. The last matching
rule wins. Chat/explore/reviewer explicitly deny edits after their read rules,
including safe example files, and cannot run tests or launch builder. Builder can
launch explore/reviewer but cannot launch itself. Code Mode's nested tools retain
their own checks; it grants no additional mutation authority.

Builder allows named Git reads, explicit-path staging/commits, established pnpm
checks, Nix validation and selected Plannotator CLI operations. Commit only within
the user's request and follow project Git conventions. Unknown shell commands,
installs and external directories ask. Pushes/destructive Git, history rewriting,
blanket staging and hook bypasses are denied. Read-only agents deny unrecognized
shell commands outright. Credential paths are explicitly protected; safe
`.env.example`/`.env.sample` reads remain allowed.

GitHub PR reads use existing `gh` access; personal also exposes the bounded
read-only `pr_context_get` tool. It accepts a PR number/URL and selected test types
(`manual`, `unit`, `playwright`) and returns revision/completeness markers. Jira
uses the existing remote Atlassian MCP/OAuth route. Named read operations are
retained from the previous config; actual tool availability and schemas must be
checked at invocation. Jira creation/updates/comments ask on builder and deny on
read-only agents. Jira deletion and unrecognized external tools remain denied.
Do not bypass a gate with CLI, browser or delegation.

Documentation lookup uses existing `ctx7 library` followed by `ctx7 docs` via
`find-docs`. Keep credential values outside Git; MCP credentials remain
machine-local. Resolve Jira site, project, Bug type and required fields before
publication; no project/site/account is invented by this migration.

Work includes one **disabled** browser server definition, pinned
`@playwright/mcp@0.0.68`, launched with `pnpm dlx`. Enable it only in the work
profile when an authorized test environment/session is available. Browser calls
ask on builder and deny on read-only agents. Exposed names and login/evidence
behavior are unverified here; adjust exact names after inspecting the server's
actual tool list. Reuse a test session or let the user sign in; keep cookies,
storage state and screenshots with private data out of Git. Browser MCP is separate
from project Playwright config/fixtures and does not establish that tests pass.

Shell allowlists do not create a workspace sandbox. Project scripts run with host
authority; use trusted repositories, scoped credentials and test data. Avoid broad
saved approvals and check on the installed runtime that saved approvals cannot
override configured denials. No blanket auto-approval is introduced.

## Repository downloads and RTK

The shared `ghgrab-fetch` skill uses [ghgrab](https://github.com/abhixdd/ghgrab)'s
non-interactive `agent tree` and `agent download` commands. It references the
[video's ghgrab chapter](https://youtu.be/II17TPAb4AQ?t=455) and covers selected
paths, explicit destinations, JSON results, authentication, and release assets.
Chat, explore, builder, and reviewer can load it. Explore
can list remote trees; downloads retain its existing shell denial. Other agents
retain their normal shell approval rules. Mise already declares `cargo:ghgrab`.

Both profiles explicitly load a dependency-free OpenCode v2 adapter for
[RTK's OpenCode hook](https://github.com/rtk-ai/rtk/tree/master/hooks/opencode)
through `./plugins/rtk` and each profile's own `plugins` directory.
It checks every shell invocation through `rtk rewrite` before execution,
including commands from subagents. RTK owns the rewrite rules: supported commands
use its filters, unsupported commands and explicit `rtk` calls pass through.
Rewrite errors fall back to the original command, with one warning per plugin
instance for an unavailable or broken binary. The rewrite subprocess uses argv,
the invocation's working directory and environment, and a two-second timeout.
Valid rewrites from RTK exit codes 0 and 3 both use OpenCode's normal permission
checks. Codes 1 and 2 with no output leave the original command for OpenCode to
evaluate; the adapter never auto-approves a command from RTK's exit status.

OpenCode evaluates permissions after this hook. Each profile mirrors its ordered
Git/GitHub CLI permission rule to its `rtk` equivalent, including denials such as
`git add -A`, history rewriting and push restrictions. Other rewrites retain the
normal ask/deny fallback; there is no blanket `rtk *` allowance. Dedicated read,
grep, and glob tools do not execute a shell and do not pass through RTK.

RTK is already declared in `nix/darwin/homebrew.nix`; `rtk rewrite` requires
version 0.23.0 or newer. This adapter targets OpenCode 2.0.20's
`ctx.shell.hook("create.before", ...)` API, rather than the upstream v1 hook.
Configured local plugins use a package directory for compatibility with 2.0.20.
Do not run `rtk init -g --opencode` over these managed profiles.

`rtk gain` reports savings; `rtk proxy <command>` preserves raw output when needed.

## Validation, activation and rollback

Run from `opencode/`:

```sh
pnpm install --frozen-lockfile
pnpm test
pnpm test:schema
pnpm test:workflows
pnpm typecheck
```

Workflow checks parse discovered agents/commands with the same frontmatter parser
as V2, validate against the pinned schemas, check exact skill discovery/profile
separation, and evaluate representative static permission fixtures. They do not
exercise runtime shell scanning, saved approvals, model calls, live Jira or a
browser session. [Migration baseline](docs/migration-baseline.md) records the
starting revision, resource inventory and revised user decisions.

After merging into each laptop's `~/.dotfiles`, inspect `opencode --version`, the
running service version, `readlink ~/.config/opencode`, profile links and any
project overrides. Check relevant variable **names**, including legacy
`OPENCODE_CONFIG`, without printing values or credentials. Resolve stale selectors
using the installed version's supported config mechanism. Apply the existing
nix-darwin host configuration and run `opencode service restart`; start a fresh
session and verify builder/default and visible chat discovery. Machine-local
`service.json` stays ignored and must not be copied between profiles.

When Nix is available, the existing host attributes can be inspected offline:

```sh
nix eval --offline ./nix#darwinConfigurations.klaus-macbook.config.system.build.toplevel.drvPath
nix eval --offline ./nix#darwinConfigurations.work-macbook.config.system.build.toplevel.drvPath
```

Live laptop, Jira, browser and model-request checks were not run. The user requested
no live workflow testing. If later validating denials, use disposable fixtures or
tool interception, never destructive actions on real data. Validate profile
separation on both laptops and use several real tasks before adding more agents
or hooks.

If agents/commands are missing, verify the profile's `agents`, `commands`, `skills`
and `AGENTS.md` targets rather than relying on prompt filenames. If routine work
asks unexpectedly, inspect the actual command/tool name and final matching rule,
including RTK's rewritten command; fix the specific rule rather than allowing
all shell commands. For Plannotator failures, check plugin loading and CLI
availability, retain the same builder target, and report an uncertain approval.

Rollback by reverting migration commits in reverse order and restoring the
recorded profile selection. Preserve session data and unrelated changes.
Configuration rollback does not undo Jira or other external mutations.

References: [V2 config](https://opencode.ai/v2/docs/config/),
[agents](https://opencode.ai/v2/docs/agents/),
[permissions](https://opencode.ai/v2/docs/permissions/),
[instructions](https://opencode.ai/v2/docs/instructions/),
[skills](https://opencode.ai/v2/docs/skills/),
[commands](https://opencode.ai/v2/docs/commands/), and
[Plannotator](https://github.com/backnotprop/plannotator/tree/main/apps/opencode-plugin).
