---
name: pr-review
description: Read a PR or diff and return traceable implementation findings or test risks without publishing a review.
---

## Inputs

PR URL or repository/number, or a local diff; requested scope and available
requirements. Use only supplied or verified repository identities.

## Procedure

1. Follow `references/pr-inspection.md` for remote PR metadata, pinned source,
   fork handling, pagination, revision freshness, and completeness checks. For a
   local diff, record HEAD and dirty paths and do not imply it matches a remote PR.
2. Inspect relevant implementation, callers, and existing tests. Keep the scope
   proportionate. Map requirements to evidence and risks; label inferred behavior.
3. Return actionable findings with severity, trigger/consequence, and file/line
   references. Include proposed manual scenarios when requested. Do not execute
   project scripts or tests, edit files, checkout branches, or publish comments.

## Output and missing evidence

Report reviewed base/head SHAs, changed-file coverage ledger, supported findings,
missing tests, and unread or inaccessible evidence. A missing/truncated diff is
partial evidence, never a complete review. Return directly to the caller.
