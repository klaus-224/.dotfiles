# Jira → PR → manual test plan

The patch adds a work-profile `/test-plan` command, three Markdown agent prompts,
a manual-test-plan skill, and the required permissions in `opencode.work.jsonc`.
It updates the existing command expectation in the configuration test.

The stages run in order: Jira retrieval → PR review → test planning → display.
`ticket-review` remains the primary coordinator. After `pr-review` returns, it
passes the complete report and Jira evidence to the `test-planner` subagent, then
displays the planner's full manual tests in the main conversation. No manual agent
switch is required. The existing implementation `planner` is separate because its
approval flow hands work to a coding agent.

## Install

**Already applied the previous two-agent patch?** Apply only the incremental update:

```sh
git apply --check ~/Downloads/test-plan-planner-update.patch
git apply ~/Downloads/test-plan-planner-update.patch
```

**Fresh installation:** use the full patch below. Do not apply both patches.


Download `jira-manual-test-plan.patch`, then run from your dotfiles checkout:

```sh
git apply --check ~/Downloads/jira-manual-test-plan.patch
git apply ~/Downloads/jira-manual-test-plan.patch
```

Adjust the download path as needed. The patch targets repository snapshot
`af73d6dfa062cd7c8961f8d4fb2945e772459241`. If your branch differs and the check
fails, merge its additions manually; do not overwrite your profile with the
provided JSON fragment. `test-plan-config.json` contains only the entries to merge
into your existing `mcp`, `command`, and `agent` objects.

Added files:

| Path under `opencode/` | Purpose |
|---|---|
| `prompts/ticket-review.md` | Retrieve Jira intent and coordinate the workflow |
| `prompts/pr-review.md` | Analyze PR changes and propose manual checks |
| `prompts/test-planner.md` | Turn completed findings and Jira evidence into manual tests |
| `prompts/jira-test-plan-command.md` | Command template with `$ARGUMENTS` |
| `skills/manual-test-plan/SKILL.md` | Test-plan format and quality rules |

The command is registered only in the work JSON profile, matching the repository's
profile-specific layout. Your Home Manager link already exposes `opencode/` as
`~/.config/opencode`; no new Nix setting is needed. Agent prompts remain plain
Markdown referenced by JSON, rather than duplicate auto-discovered definitions.
Models inherit your selected OpenCode model; add model/variant overrides only
if you want these agents to use different ones.

Authenticate from a terminal:

```sh
OPENCODE_CONFIG="$HOME/.dotfiles/opencode/opencode.work.jsonc" opencode mcp auth atlassian
gh auth status
```

If GitHub is not authenticated, run `gh auth login`. Use an identity that can read
the relevant private repositories. If supplying a fine-grained GitHub token, grant
repository Metadata, Contents, and Pull requests read access; no write access is
needed for this workflow.

Launch OpenCode in the application repository:

```sh
OPENCODE_CONFIG="$HOME/.dotfiles/opencode/opencode.work.jsonc" opencode
```

Then run:

```text
/test-plan PROJ-123
/test-plan PROJ-123 https://github.com/org/repo/pull/456
/test-plan PROJ-123 repository org/repo; staging; admin and member roles
```

## Permissions

These are included in the patch and JSON fragment. Keep them under each agent's
`permission`, rather than broadly enabling them globally.

| Agent | Enabled |
|---|---|
| `ticket-review` | `question`; delegation only to `pr-review` and `test-planner`; skill loading denied |
| `ticket-review` | Atlassian resource discovery; issue reads; paginated comment and remote-link reads; JQL search |
| `pr-review` | Local `read`, `glob`, `grep`, `list`; specific `gh` inspection commands; Git HEAD/status checks |
| `test-planner` | Only the `manual-test-plan` skill; questions and evidence requests returned through the coordinator |
| All three | Default deny; no editing, publishing, test execution, or general shell access |

When merging into an already configured workflow, replace the old
`ticket-review.permission.skill` object with `"deny"`, add `"test-planner": "allow"`
to its `task` object, and add the new `agent.test-planner` entry. The reviewer keeps
`task: "deny"`; the coordinator owns the handoff. The planner has no Jira/GitHub,
shell, editing, delegation or `submit_plan` access.

Exact Atlassian allow entries:

```text
atlassian_getAccessibleAtlassianResources
atlassian_getJiraIssue
atlassian_listJiraIssueComments
atlassian_listJiraIssueRemoteIssueLinks
atlassian_getJiraIssueRemoteIssueLinks  (legacy compatibility)
atlassian_searchJiraIssuesUsingJql
```

The patch sets the existing `atlassian` connection to
`https://mcp.atlassian.com/v2/mcp?tools=all`. Atlassian documents this as the flat,
paginated tool list. It permits exact read-tool allow entries without granting
the generic `executeRead` dispatcher. Organization access must include Jira read
and search groups (`read:jira:agent-interface`, `search:jira:agent-interface`).
Actual exposed names depend on the connection and server; if one differs, replace
that exact permission after checking the tool schema. Do not enable `atlassian_*`
or generic write/destructive dispatchers. The flat list adds tool-discovery overhead.

GitHub shell access is limited to PR list/view/diff, repo identity, GET requests
for PR file inventories and repository contents, and Git status/HEAD checks.
OpenCode command-pattern permissions are guardrails, not an operating-system
sandbox; repository access should also be limited through the GitHub identity.

## Expected result and checks

The coordinator displays the planner's complete Markdown in the conversation: summary, reviewed PR SHAs,
preconditions, criterion-to-test mapping, numbered scenarios, expected outcomes,
file coverage, and unresolved risks. It does not execute tests or publish the plan.

Try one known ticket with a linked PR. Verify the issue/PR identities, criterion
coverage, and code references. If links are absent, the reviewer searches the
current or supplied repository; if still ambiguous, it asks. Missing PR access
produces a visibly incomplete requirements-only draft.

The updated files were checked for JSON/JSONC syntax, references, permission
structure and clean application of both patch paths. Live OpenCode/Jira/GitHub
execution and the agent handoff were not tested.
The repository's existing test suite also contains expectations inconsistent with
the supplied baseline (including profile defaults and missing registrations);
this change does not claim to repair that unrelated drift.

## References

- [OpenCode agents and permissions](https://opencode.ai/docs/agents/)
- [OpenCode commands](https://opencode.ai/docs/commands/)
- [OpenCode skills](https://opencode.ai/docs/skills/)
- [Atlassian supported tools and permission groups](https://support.atlassian.com/atlassian-ai-gateway/docs/supported-tools/)
- [GitHub CLI API inspection](https://cli.github.com/manual/gh_api)
