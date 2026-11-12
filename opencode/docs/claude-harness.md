# Claude-style agent harness

The harness helps `builder` investigate, edit, verify, and save progress in
OpenCode 2.0.20. It works with either profile and the selected provider. It does
not require an Anthropic account or install a `claude` command.

## Use the harness

After merging the files into your active dotfiles checkout:

1. Select `opencode-profile personal` or `opencode-profile work`.
2. Run `opencode service restart`.
3. Start a fresh builder session.

The `plugins` link exposes `shared-plugins/claude-harness`. Changes in a separate
worktree do not update your active configuration.

Ask builder, for example: “Find the parser bug, fix it, and run the relevant
tests.” For a long task, ask “Show the harness checkpoint” to inspect saved
progress. Resume through OpenCode's normal session controls. There is no separate
transcript or model connection to manage.

## Agents and permissions

| Agent | Role |
| --- | --- |
| Builder | Owns the task, integration, checks, and final response; can launch explore, reviewer, and worker |
| Chat | Read-only discussion; can launch only explore |
| Explore | Read-only research |
| Reviewer | Read-only review |
| Worker | Bounded implementation; cannot delegate, submit a plan, commit, or push |

Child agents start with fresh context and use their own permission rules. Worker
receives no blanket permission grant from builder. Credential, external-directory,
destructive-command, and external-write gates still apply.

Worker uses the parent's selected model unless a repository overrides it. Work
allows only Copilot; personal allows only OpenCode and OpenAI. RTK and Plannotator
remain registered. The harness does not change dependency pins or editor schemas.

## What the harness adds

OpenCode runs the model/tool loop, streams responses, validates tools, enforces
permissions, handles cancellation, and runs subagents. The harness adds:

| Feature | Behavior |
| --- | --- |
| Checkpoints | `harness_checkpoint` saves progress; `harness_status` reads it |
| Context recovery | Adds continuation instructions and the checkpoint to native compaction |
| Retry ceiling | Allows at most three request attempts by default, including the initial request |
| Repeated-failure guard | After three consecutive identical failed tool calls, hides that tool for one model request and explains the failure |

Native delegation depth defaults to one. Worker cannot delegate. Builder has an
80-step limit; worker has a 40-step limit.

### Checkpoints

Each session has one checkpoint. Saving a new checkpoint replaces the old one.
It contains the objective, phase, completed work, next steps, and evidence. Valid
phases are `investigate`, `implement`, `verify`, `blocked`, and `complete`. Field
lengths and total size are limited.

The `complete` phase requires evidence and no remaining steps. This validates
the record, not its claims. It does not stop the loop or prove that tests passed.
The agent must check actual tool results.

Checkpoints persist in OpenCode's plugin storage, outside the repository. They
return to model context after reload and compaction and are sent to the selected
provider. **Do not include secrets.**

Checkpoints are fallible model-authored notes. New user instructions take
precedence. Builder should update the objective when the task changes.

### Retries and repeated failures

To change the request-attempt ceiling, replace the harness string entry in
`opencode.json` with this object:

```json
{
  "package": "./plugins/claude-harness",
  "options": { "maxAttempts": 3 }
}
```

`maxAttempts` accepts integers from 1 to 10. A value of 1 disables retries. The
harness never retries an error that OpenCode rejects or shortens a Retry-After
delay. Step limits are separate settings at `agents.<id>.steps`. These limits do
not cap total spending: retries and extra summary calls can add requests.

The failure guard reads tool calls and their settled results from the transcript,
including runtime failures that bypass the native tool hook. A success, changed
arguments, or a new user prompt breaks the failure streak. The tool returns after
one model request. This encourages a different approach; it does not replace
permissions.

The guard remembers the last handled call ID for up to 128 sessions. Plugin
reload clears these IDs, so an existing failure streak can trigger another
recovery round. Checkpoints persist across reloads.

## Limits and differences from Claude Code

The harness uses OpenCode's engine. It does not reproduce Claude's CLI flags,
wire formats, private prompts, Anthropic-specific caching, remote isolation,
worktree management, exact tool scheduler, or a hard limit on concurrent children.
File ownership and task order rely on agent instructions. OpenCode controls
scheduling and enforces permissions and depth limits.

OpenCode 2.0.20 has no general completion/stop plugin hook. The harness cannot
guarantee that a model finishes every task or restart every incomplete task. It
does not replay tools after provider failures. Completion still depends on the
model.

## Verification

Run from `opencode/`:

```sh
pnpm test
pnpm test:harness:runtime
pnpm typecheck
pnpm test:schema
pnpm test:workflows
TMPDIR=/private/tmp pnpm test:profiles  # canonical temporary path on macOS
```

Unit tests cover checkpoint persistence and session isolation, cancellation,
input limits, compaction hooks, failure streaks, retry decisions, and pinned
schema validation.

The runtime fixture starts a real OpenCode process with a scripted local model
and isolated configuration and storage. It copies the plugin outside the
repository to check runtime resolution, then tests tool exchange, plugin reload,
real compaction, foreground and background workers, tool failures, and exhausted
retries. It requires the OpenCode 2.0.20 binary and filesystem-watch access on
macOS. It uses no account credentials or external model.

Previously recorded baseline failures: `test:schema` expected a missing editor
schema reference/file; `test:workflows` expected agent metadata in a shared
command. Harness tests validate configuration separately against the pinned
schema. The harness change did not regenerate or repair those unrelated files.

## Implementation references

The design used static analysis reports for Claude Code 2.1.312: `agent-loop.md`,
`architecture.md`, and their HTML/JSON explainer. Those reports had known gaps.
No recovered Claude code or proprietary prompt text is included.

The integration uses OpenCode 2.0.20's pinned interfaces:
[session hooks](https://github.com/anomalyco/opencode/blob/v2.0.20/packages/plugin/src/promise/session.ts),
[native subagents](https://github.com/anomalyco/opencode/blob/v2.0.20/packages/core/src/tool/plugin/subagent.ts),
[retry accounting](https://github.com/anomalyco/opencode/blob/v2.0.20/packages/core/src/session/runner/retry.ts),
and [compaction](https://github.com/anomalyco/opencode/blob/v2.0.20/packages/core/src/session/compaction.ts).
