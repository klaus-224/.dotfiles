# Configuration audit integration results

## Integration

Baseline HEAD: `7ef7a56b86aa6c866f320d1928d817d3eb23768b`.
Two workers ran in parallel in `~/code/dotfiles-audit/checkpoints-1-4`
(`chore/config-audit-1-4`) and `checkpoints-5-8`
(`chore/config-audit-5-8`). Each reviewed its complete changes and reported checks.
The coordinator reviewed and combined their patches in `~/.dotfiles`; this was
not a Git branch merge. No commits, staging, pushes, or activation were performed.
Both worktrees remain for inspection.

Pre-existing changes were backed up in
`~/code/dotfiles-audit/backup-7ef7a56/initial.patch` and `untracked.tar`, then copied
to worker A. The index was initially empty and remains unstaged. Original deleted
agent definitions, audit prompts and archived prompts were preserved. The user's
work-profile/chat changes were extended, not restored from HEAD or applied twice.

Integration fixes connected the Node hook suite to shared validation, corrected
ownership/PATH documentation, separated offline and network schema tests, and
fixed a macOS ENOTDIR test fixture by using an actual empty PATH directory.

## Combined checks

- `just validate`: passed (8 Python audit tests, 15 OpenCode tests, 8 Git/terminal
  tests, references, executable modes, Zsh syntax, ShellCheck, TypeScript).
- `just doctor`: zero failures. Optional tools missing: `ctx7`, `agent_memory`,
  `session_reader`, and the personal-only `postgres-language-server` on this work Mac.
- `just validate-schema`: passed for both profiles against the current official
  OpenCode schema; no plugins, providers or MCP servers were loaded.
- Plannotator setup-goal skill tests: 3 passed.
- Both combined Nix host system derivations evaluated offline with lock writes
  disabled; combined offline build dry-run passed. Upstream Nix emitted an
  `options.json` derivation-context warning.
- `git diff --check`: passed; HEAD and staged state unchanged.

## Outstanding verification and decisions

- Full Nix builds were not run: dry-run listed a large uncached toolchain closure.
- Fresh-machine bootstrap, actual editor/terminal behavior, live OpenCode
  providers/plugins/MCP, and deployed Home Manager migration require manual checks.
- Inspect the existing whole-directory `~/.local/bin` symlink before activating
  individual links; see [migration guidance](config-audit.md#managed-links-migration-and-rollback).
- Global Git hook scope and live config links intentionally remain. Hook opt-in
  migration is deferred rather than silently disabling existing protections.
- The pre-existing npm lockfile is stale (`npm ci` failed in worker A); a frozen
  pnpm install succeeded there. Lockfiles were left unchanged. Reconcile the
  redundant npm lock before relying on npm provisioning.
- No real-home shell benchmark, credential scan, database inspection, destructive
  cleanup, or system activation was performed during implementation.
