# Model fallback

The local `dotfiles.model-fallback` plugin (version 1.0.0) targets the pinned
OpenCode 2.0.20 API. Home Manager links `opencode-fallback.jsonc` into the OpenCode
config directory. It does not activate the host configuration.

The preference order is:

1. `openai/gpt-6.1-sol`
2. `opencode/claude-opus-5-5`
3. `opencode/kimi-k3`
4. `opencode/glm-5.3`
5. `opencode/glm-5.3-flash`

The primary becomes the registry default when available. Explicit config/session
model selections can override that default. All agents inherit the same global
policy; this change does not introduce per-agent model assignments. Only failures
from models in this chain are routed, proceeding forward from the selected model.

Both machines load the plugin. It considers only enabled, tool-capable models in
OpenCode's policy-filtered available inventory. The work machine's Copilot-only
policy therefore leaves its default and retries unchanged. It never registers new
providers or credentials, changes a billing route, or bypasses provider policy.
The owner selected all four proposed fallbacks; catalog presence alone still does
not prove account entitlement or subscription coverage. Models may share a quota.

## Behavior

On HTTP 429, selected provider failures (500/502/503/504), quota/usage-limit
errors, or an API-level model-not-found response, the plugin switches the session
model and asks OpenCode to retry immediately. Unavailable or cooling-down
candidates are skipped. Authentication/permission failures, cancellation, invalid
requests, and context overflow retain native behavior. A model missing from the
local inventory can be skipped at prompt admission; it is not itself a provider
error and never reaches the retry hook.

The plugin uses v2's native `session.hook("retry")` and `session.switchModel`.
OpenCode rebuilds the next attempt's context from the existing session. The plugin
does not resubmit the user's prompt, rerun tools, or synthesize a continuation.
Native handling still determines recovery after partial streams. Compaction and
auxiliary requests retain their own behavior. Context exhaustion is not quota
exhaustion.

Each user prompt allows at most four model switches. Failed models cool down for
300 seconds across sessions in the same project/plugin instance. After expiry,
a later prompt returns to the original selection, including its variant, unless
the user has selected another model. Variants are not copied to a different model.
The cooldown is a retry opportunity, not a subscription-reset detector. Runtime
state resets when the plugin reloads and retains at most 1,000 session preferences.
No timeout interrupts slow reasoning. Exhausting the chain stops retries and leaves
the native error visible. Model-selection events update the UI; with
`notify_on_fallback`, concise switch/exhaustion notices also go to the server log.
No prompt, tool output, credentials, or raw error body is logged by this plugin.

## Configuration and disablement

Edit the repository source, then use your normal Home Manager deployment workflow.
Discovery uses the first existing file in this order:

1. `<project>/.opencode/opencode-fallback.jsonc`
2. `<project>/.opencode/opencode-fallback.json`
3. `<OpenCode config directory>/opencode-fallback.jsonc`
4. `<OpenCode config directory>/opencode-fallback.json`

The global directory honors `OPENCODE_CONFIG_DIR`, then
`$XDG_CONFIG_HOME/opencode`, then `~/.config/opencode`. Project configuration
replaces the entire policy. JSONC supports comments and trailing commas. Invalid
settings fail plugin initialization rather than silently selecting another policy.
Missing configuration or `enabled: false` disables routing. To restrict spending,
remove any separately billed models from the source chain. Configuration is loaded
at plugin setup; restart OpenCode after editing this separate policy file.

The evaluated third-party candidate, [opencode-runtime-fallback 0.2.3](https://github.com/youngbinkim0/opencode-fallback),
uses the v1 `@opencode-ai/plugin` interface. It is not installed. This implementation
uses the [v2 plugin API](https://dev.opencode.ai/v2/docs/build/plugins) and keeps the
existing SDK pin and generated editor schema unchanged.

## Verification

From `opencode/`:

```sh
pnpm test
pnpm test:schema
pnpm test:workflows
pnpm typecheck
pnpm test:fallback:runtime
```

The runtime check requires the OpenCode 2.0.20 executable. It starts a private
server with temporary config/data/cache/home directories and a localhost mock
provider. It completes a tool on the primary, returns a simulated HTTP 429 on the
next model request (429 or model-not-found 404), and verifies that a second provider receives the conversation
and tool result while the tool executes exactly once. It also exhausts all four backups and checks that retries stop. No live account
credentials or paid inference are used. Unit checks cover all-chain failure, attempt bounds,
cooldown recovery, policy filtering, manual selection, and configuration precedence.

These checks do not establish real account entitlement, availability, or detection
of every provider's quota response. After deployment, verify a small request with
each real model and the intended billing route. Capture a real quota failure when
one occurs before treating that specific provider response as proven. Keep that
account-specific evidence and credentials outside Git.
