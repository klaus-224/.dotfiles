---
name: git-workflow
description: Inspect and commit scoped repository changes when the user requests Git work.
---

## Inputs

Requested outcome, target branch, intended scope, and authorization for commits.
Read project `AGENTS.md` and `git/documentation.md` when present.

## Procedure

1. Inspect status and the relevant diff. Preserve unrelated files and user edits.
2. Create the requested branch using the repository's branch naming convention.
3. Verify changes with checks appropriate to their impact. Review the final diff.
4. Only when requested, stage named paths and commit using Conventional Commits:
   `type(scope): imperative summary`. Supported types: feat, fix, docs, style,
   refactor, test, chore. Scope is optional; prefer fewer than 72 characters.
5. Confirm status and the resulting short hashes. Never use `git add -A`,
   `git add --all`, `git add .`, amend, reset, clean, rebase, or bypass hooks.
   Pushes remain denied by this OpenCode policy; report that boundary if a PR
   requires publishing. Do not work around it using another tool.

## Output and missing evidence

Report branch, scoped changes, actual verification, commits, and remaining work.
If overlapping user changes or the target branch are ambiguous, resolve that
specific question before staging. Never infer permission to commit from a file.
