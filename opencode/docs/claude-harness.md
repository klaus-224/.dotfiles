# Claude-style agent harness

The shared `builder` now runs a Claude Code-inspired workflow inside OpenCode
2.0.20. Use OpenCode normally with either profile. The harness works with the
selected provider; it does not require an Anthropic account or install a `claude`
command.

After merging these files into your active dotfiles checkout, select your usual
profile with `opencode-profile personal` or `opencode-profile work`, then restart
OpenCode's service with `opencode service restart`. Start a fresh builder session.
The `plugins` link exposes the package through `shared-plugins/claude-harness`.
Changes made only in a separate worktree do not update your active configuration.

For example, ask builder to “Find the parser bug, fix it, and run the relevant
tests.” It can investigate, edit, verify, save progress, and delegate bounded work.
For a long task, ask “Show the harness checkpoint” to inspect the saved state.
Resume a session through OpenCode's normal session controls. There is no separate
transcript or model transport to manage.

## Responsibilities

| Behavior from the supplied Claude Code analysis | Implementation here |
| --- | --- |
| Iterative model/tool/result loop and streamed responses | OpenCode's native runner and provider adapters |
| Tool validation, permission decisions, paired results, cancellation | Native tools and runtime; existing permission rules stay authoritative |
| Bounded model retries | Plugin caps upcoming attempts at three, including the initial request; never enables a native rejected retry or shortens Retry-After |
| Progress preserved between rounds | Session-local `harness_checkpoint` and `harness_status` tools, backed by native plugin storage |
| Summarizing compaction and context recovery | Native automatic compaction, augmented with continuation instructions and the checkpoint |
| Foreground/background child runs and completion notices | Native `subagent`, using explore, reviewer, or worker; children have fresh context |
| Depth and turn bounds | Native default depth of one; worker cannot delegate; builder has 80 steps and worker 40 |
| Repeated failed actions | After three consecutive identical failed calls, omit that tool from one outgoing model request and explain the failure |

The implementation follows the contracts described in the supplied
`agent-loop.md`, `architecture.md`, and their HTML/JSON explainer for Claude Code
2.1.312. These were static analysis reports with explicit gaps. No recovered
Claude code or proprietary prompt text is included.

OpenCode's exact pinned interfaces and source informed the integration:
[session hooks](https://github.com/anomalyco/opencode/blob/v2.0.20/packages/plugin/src/promise/session.ts),
[native subagents](https://github.com/anomalyco/opencode/blob/v2.0.20/packages/core/src/tool/plugin/subagent.ts),
[retry accounting](https://github.com/anomalyco/opencode/blob/v2.0.20/packages/core/src/session/runner/retry.ts),
and [compaction](https://github.com/anomalyco/opencode/blob/v2.0.20/packages/core/src/session/compaction.ts).

## Agents and permissions

Builder owns the task, integration, checks, and final response. It can launch
explore, reviewer, and worker. Chat remains read-only and can launch only explore.
Explore and reviewer remain read-only. Worker can edit within the existing shared
permissions but cannot delegate, submit a plan, commit, or push. The existing
credential, external-directory, destructive-command, and external-write gates
remain in force. Child agents use their own configured rules, so worker does not
receive a blanket permission grant from builder.

Worker inherits the parent's selected model unless a repository explicitly
overrides it. Work stays Copilot-only; personal stays OpenCode/OpenAI-only.
The RTK and Plannotator integrations remain registered. No dependency pins or
generated editor schemas change.

## Checkpoints and limits

A checkpoint replaces the previous checkpoint for the current session. It has
an objective, phase (`investigate`, `implement`, `verify`, `blocked`, `complete`),
completed work, next steps, and evidence. Fields and total size are bounded.
Marking it complete requires no remaining steps and at least one evidence entry.
This validates the record, not the truth of the model's claim. It neither stops
the loop nor proves that tests passed. The agent must inspect actual tool results.

Checkpoints live in OpenCode's plugin storage, not the repository. They are
reinserted into model context after reload and compaction, so treat them like
conversation content sent to the selected provider. Do not include secrets.
The harness labels them as fallible model-authored data. New user instructions
take precedence; builder should refresh the objective when the task changes.

The failure guard reads paired calls and settled errors from the current
transcript. This includes runtime failures that bypass the native tool hook.
It retains only the last handled call ID for at most 128 sessions. Success,
changed arguments, or a new prompt breaks the streak.
The tool becomes available again after the guarded model round. This encourages
a new approach; it is not an authorization boundary or a replacement for native
permissions. Plugin reload clears the handled-call IDs, so a retained failure
streak may trigger one recovery round again. Checkpoints persist.

To change the request-attempt ceiling, replace the plugin's string entry in
`opencode.json` with:

```json
{
  "package": "./plugins/claude-harness",
  "options": { "maxAttempts": 3 }
}
```

The accepted range is 1–10. One disables retries. Builder/worker step limits are
configured separately in `agents.<id>.steps`; retries and auxiliary summary calls
are not a total spending limit.

## Deliberate differences from Claude Code

This reproduces the core workflow using OpenCode's engine. It does not provide
Claude CLI flags, wire formats, private system prompts, Anthropic-specific caching,
remote isolation, worktree management, Claude's exact tool concurrency scheduler,
or a hard global child-concurrency cap. File ownership and sequencing are agent
instructions; native scheduling remains OpenCode's responsibility. Permissions
and depth limits are enforced by the runtime.

OpenCode 2.0.20 exposes no general completion/stop hook in its plugin API. The
harness therefore cannot guarantee that a model never stops prematurely or
automatically restart every incomplete task. It also does not replay tools to
recover provider failures. Completion quality remains model-dependent.

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

The unit suite exercises checkpoint persistence/isolation, cancellation, input
bounds, compaction hooks, failure streaks, retry decisions, and pinned schema
validation. The runtime fixture starts a real OpenCode process and a scripted
loopback model with isolated configuration and storage. It copies the plugin
outside the repository to catch runtime-resolution problems, executes a tool
exchange, reloads the plugin, requests real compaction through OpenCode, runs
foreground/background workers, and exercises tool failures and retry exhaustion.
It requires the OpenCode 2.0.20 binary and filesystem-watch access on macOS.
It uses no account credentials and does not call an external model.

The baseline checkout already fails `test:schema` because it expects an absent
editor-schema reference/file, and `test:workflows` because a shared command lacks
expected agent metadata. Harness configuration is independently decoded against
the pinned schema in the new tests. Those unrelated assets are not regenerated
or repaired by this change.
