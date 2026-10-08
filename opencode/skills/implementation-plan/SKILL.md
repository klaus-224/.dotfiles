---
name: implementation-plan
description: Let builder optionally plan through Plannotator and then resume its own approved implementation.
---

## Trigger and inputs

Use only for `/build-plan` or an explicit request for Plannotator planning before
implementation. Required: requested outcome, repository, constraints, and whether
implementation is requested. Run in builder with a read-only planning phase.
A planning-only request stays in that phase and never starts implementation.

## Procedure

1. Inspect project instructions, working-tree changes, relevant implementation,
   and checks. Use explore for a bounded question when helpful. Do not edit.
2. Resolve outcome-changing ambiguities; propose a proportionate plan with scope,
   intended changes, relevant verification, risks, and commit policy. Preserve
   unrelated changes. Do not require a research or reviewer handoff for every task.
3. Call `submit_plan` with `edits: [{start: 1, content: <complete plan>}]` for a
   new plan. If a previous plan is shown, use its line numbers to replace it rather
   than appending a new task to stale content. On change requests, apply the
   feedback with targeted line edits and resubmit. Do not implement on rejection,
   dismissal, malformed output, or tool failure.
4. For requested implementation, tell the user to select **builder** as the
   approval target in Plannotator. Approval with that selection retains the same
   builder agent and configured model for implementation. Do not select disabled
   build/plan or launch yourself as a subagent. For planning-only work, keep the
   approval target disabled and do not implement, even if the tool suggests it.
5. After approval, resume as builder: implement the approved scope, check/review the
   diff, fixes in-scope issues, and reports the result. If the host does not switch
   agent or reports an uncertain approval, remain in the planning phase and
   report the blocker. An approved plan alone does not authorize unrelated external writes.

## Output and missing evidence

Return the complete plan and its approval state. Builder reports completed
changes, actual checks, and blockers. If Plannotator or repository access is
unavailable, report the concrete blocker; do not claim approval or switch to an
implementation path silently. Direct builder tasks do not require this skill.
