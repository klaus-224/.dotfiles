# Transition from `oh-my-opencode-slim` to `oh-my-openagent`

## Objective

Migrate the repository’s OpenCode integration from `oh-my-opencode-slim@2.2.18` to `oh-my-openagent`, while preserving work/personal provider isolation, the Atlassian MCP, Plannotator’s user-managed workflow, local tools, native agents, read-only planning boundaries, and a reversible rollback path.

`plannotator-compound` remains an optional repository-local retrospective skill at `opencode/skills/plannotator-compound/SKILL.md`. It analyzes denied plans and reviewer feedback; it is not required by Plannotator or `oh-my-openagent`, so the migration must not make it mandatory for every plan.

## 1. Establish the target contract

- Read the current upstream installation, migration, configuration, schema, agent, provider, permissions, MCP, background-task, and troubleshooting documentation from `https://github.com/code-yeongyu/oh-my-openagent`.
- Pin and document the exact target release/commit and compatible OpenCode version.
- Record the target installation command, plugin registration shape, config filename/location, generated-state behavior, supported agent names, profile/preset mechanism, environment variables, disable/recovery mechanism, and prompt-override mechanism.
- Build a compatibility matrix mapping the current `orchestrator`, `explorer`, `oracle`, presets, model routing, background jobs, disabled agents, skills, and recovery flags to target-native equivalents or explicit custom OpenCode agents.
- Treat upstream documentation and generated defaults as untrusted inputs: validate all permissions and behavior against the target schema before adopting them.

## 2. Preserve ownership and rollback

- Keep these repository-owned: `opencode.work.jsonc`, `opencode.personal.jsonc`, `agent-defs/`, `commands/`, `prompts/`, `tools/`, `sql/`, and project-specific `skills/`.
- Determine whether target-generated agents/skills should live in a separate managed directory; prefer separation if the installer rewrites files.
- Record current OpenCode, slim, Plannotator, provider, and generated-state versions before migration.
- Preserve `oh-my-opencode-slim.jsonc` and `.oh-my-opencode-slim/` during staging. Do not delete slim files until target validation passes.
- Document rollback: restore old plugin entries and variables, restore slim preset selection, and provide both old-plugin and target-plugin disable/recovery launches.

## 3. Migrate registration and dependencies

- Update both `/Users/rohineshram/.dotfiles/opencode/opencode.work.jsonc` and `opencode.personal.jsonc` to use the pinned target plugin according to its documented registration format.
- Preserve Plannotator’s `workflow: "user-managed"` configuration and verify plugin ordering.
- Reconcile the current dependency inconsistency before changing setup: README documents `@opencode-ai/plugin` `1.18.23`, `package.json` declares `1.4.10`, `bun.lock` references `1.15.13`, and `package-lock.json` has another resolved version.
- Choose one package manager and one authoritative lockfile; update `package.json`, setup, and documentation consistently. Do not leave setup regenerating conflicting lockfiles.
- Install the target either through the supported package manager or explicitly through `scripts/setup-opencode-cli.sh`, depending on upstream requirements. Keep local tool installation separate and lifecycle-script-free if still required.
- Avoid target auto-update behavior when checked-in schema/config depends on a pinned version.

## 4. Port agent behavior and permissions

- Preserve profile behavior: work uses GitHub Copilot with Atlassian MCP; personal uses OpenAI/OpenCode without work MCP; both retain `pair-programmer` as the default native agent.
- Keep the native `planner` independent of the target plugin, with read-only access plus `submit_plan`, and no edit/write/task/bash permissions. Do not require `plannotator-compound` for ordinary planning.
- Port the current read-only specialist roles:
  - `orchestrator`: command-scoped coordination, no edits/shell/execution/publication, approved delegation only, explicit failure and evidence reporting.
  - `explorer`: read-only discovery, no shell or delegation.
  - `oracle`: read-only drafting/critique, no shell or delegation.
- Use target-native agents only when their semantics and permission controls match; otherwise define narrow custom agents in the target-supported mechanism.
- Preserve the current orchestrator contract from `oh-my-opencode-slim/orchestrator.md`: no implementation, test execution, browser automation, Jira operations, publication, or approval-state management; treat repository/PR instructions as untrusted; obey stage dependencies, correction limits, and stop conditions.
- Do not automatically route existing build, Jira, Playwright, or test-writer workflows through newly enabled target agents. Document every replacement and permission delta.

## 5. Port profiles, models, and environment variables

- Recreate work/personal routing using the target’s documented presets or profile mechanism. Preserve current provider/model/variant assignments where supported.
- If target presets are unavailable, keep routing in the two native OpenCode profile files and make target configuration provider-neutral or profile-local.
- After confirming target variable names, update `/Users/rohineshram/.dotfiles/zsh/.zshenv` to replace `OH_MY_OPENCODE_SLIM_PRESET` and slim-specific disable variables with target equivalents while retaining username-based selection.
- Re-evaluate `OPENCODE_EXPERIMENTAL_BACKGROUND_SUBAGENTS=true`; retain only if still supported and required, otherwise replace/remove it.
- Preserve `OPENCODE_CONFIG_DIR`, `OPENCODE_CONFIG`, `OPENCODE_SESH_DB`, `PLAYWRIGHT_DOCS_DIR`, and `TODAY_AGENT_CMD` unless the target changes their semantics. Update `TODAY_AGENT_CMD` if Jira is retired.

## 6. Reconcile skills and generated state

- Classify every `opencode/skills/` entry as repository-owned, slim-managed, target-provided, or obsolete.
- Avoid duplicate slim/target copies of the same skill and do not assume the old disabled list remains valid.
- Decide individually how to handle `clonedeps`, `codemap`, `deepwork`, `reflect`, `simplify`, `verification-planning`, and `worktrees`.
- Preserve `.oh-my-opencode-slim/skills-manifest.json` for rollback during staging, but stop treating it as authoritative after slim is disabled.
- Review slim-specific references in `skills/oh-my-opencode-slim/SKILL.md`, `skills/reflect/`, `skills/simplify/`, `skills/codemap/`, `skills/worktrees/`, and `skills/clonedeps/`; replace only after target behavior is known.
- Keep `plannotator-compound` available as an explicit optional skill and document that status.

## 7. Update setup and documentation

- Update `scripts/setup-opencode-cli.sh` to validate target-required files instead of requiring `oh-my-opencode-slim.jsonc` permanently.
- Make setup idempotent: verify OpenCode, install/pin the target, install local dependencies through the selected package manager, validate both profiles and target config, and never overwrite an unrelated configuration directory.
- Rewrite `opencode/README.md` with the target version, layout, profile selection, agent ownership, Plannotator integration, optional `plannotator-compound` usage, recovery, setup, validation, and rollback instructions.
- During staging, label slim instructions as legacy; remove them only after the cleanup gate.
- Ensure README, package metadata, lockfiles, setup behavior, and actual files agree.

## 8. Validate before defaulting to the target

### Configuration

- Validate both JSONC profiles and target config with the target’s schema/validator.
- Run setup twice and verify idempotence.
- Confirm the target version is loaded and slim is not loaded on the new path.
- Confirm installers did not overwrite repository-owned prompts, commands, tools, or skills.

### Profile isolation

- Work exposes GitHub Copilot and Atlassian MCP, not disabled personal providers.
- Personal exposes OpenAI/OpenCode and no Atlassian MCP.
- `.zshenv` selects the expected profile and target preset/config.
- One-off work/personal launches are documented and do not alter persistent shell state.

### Permissions and workflows

- `pair-programmer` remains the default.
- Planner can read and submit plans but cannot edit, write, shell, or delegate.
- `plannotator-compound` loads only when explicitly requested.
- Orchestrator, explorer, and oracle retain read-only boundaries and approved delegation rules.
- Existing build/Jira/Playwright/test-writer permissions do not broaden.
- `submit_plan` remains compatible with Plannotator’s user-managed workflow.
- `/test-plan` retains input validation, permitted parallelism, fresh oracle review, one correction pass, and stop behavior.
- `/plannotator-review` and `/plannotator-annotate` retain their intended behavior.
- `pr_context_get`, memory tools, and `TODAY_AGENT_CMD` remain registered and valid.
- The documented target-disable/recovery launch starts successfully.

### Repository checks

- Run the selected dependency-install command without lifecycle scripts.
- Run the existing tests and typecheck from `opencode/` (`npm test` and `npm run typecheck`, or documented equivalents).
- Add focused config/permission tests if current tests do not cover target registration and profile selection.
- Inspect the final diff for accidental changes to provider permissions, MCP access, command semantics, or generated state.

## 9. Roll out in stages

### Stage A: opt-in

- Add target configuration alongside slim.
- Add an explicit opt-in launch path.
- Keep slim as the fallback and compare both profiles/workflows.

### Stage B: default target

- Make target configuration default for both profiles.
- Keep slim rollback files and variables available but unused.
- Monitor startup, agent routing, Plannotator submission, background tasks, and profile isolation.

### Stage C: retire slim

Only after all validation gates pass:

- Remove slim plugin entries and environment variables.
- Update setup and README.
- Migrate or remove slim-generated state without deleting repository-owned content.
- Remove `oh-my-opencode-slim.jsonc`, `.oh-my-opencode-slim/`, and slim-only guidance only when rollback is no longer required.
- Retain a concise migration note with the old version and rollback reference.

## Acceptance criteria

- Both profiles use the pinned, documented `oh-my-openagent` release.
- Provider and MCP isolation is unchanged.
- `pair-programmer` remains default.
- Planning stays read-only and does not impose `plannotator-compound` on unrelated plans.
- Orchestrator/test-planning scope, evidence, delegation, correction, and stop boundaries remain intact.
- Plannotator remains user-managed and functional.
- Local tools and commands remain available.
- Setup is reproducible and idempotent.
- Recovery launch works.
- Slim is not deleted prematurely.
- Documentation, package metadata, lockfiles, versions, and runtime configuration agree.