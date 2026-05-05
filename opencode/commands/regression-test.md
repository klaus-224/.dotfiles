---
description: Plan and write Playwright regression tests via 3-planner debate workflow
agent: general
---

Run the regression test planning and writing workflow.

## Input

Arguments: `<DESCRIPTION>`

A description of the feature or area to write regression tests for.

Example:

- `/regression-test source panel filtering and search functionality`
- `/regression-test map polygon drawing and editing`

## Flow

### Round 1 — Planning (3 separate parallel agents)

You MUST call the Task tool exactly 3 times in a SINGLE message to launch 3 independent `regression-planner` subagents simultaneously. Each is a separate agent session with its own context. Do NOT run them sequentially.

Call the Task tool 3 times in one message with these prompts:

- Task 1 (subagent_type: `regression-planner`): `Plan regression tests for: <DESCRIPTION>. Perspective: happy path. Focus on core user flows that must always work.`
- Task 2 (subagent_type: `regression-planner`): `Plan regression tests for: <DESCRIPTION>. Perspective: edge cases. Focus on boundary conditions, unusual inputs, and corner cases.`
- Task 3 (subagent_type: `regression-planner`): `Plan regression tests for: <DESCRIPTION>. Perspective: error states. Focus on failure modes, error handling, and recovery.`

Each returns a `plan_id` and a `task_id`. Save both — you need the `task_id` to resume each agent's session in later rounds.

### Round 2 — Critique (3 separate parallel agents, resumed)

You MUST call the Task tool exactly 3 times in a SINGLE message, resuming each planner's session using their `task_id` from Round 1. Each agent is independent.

- Resume Task 1 (task_id from planner 1): `Review all 3 plans: [plan_id_1], [plan_id_2], [plan_id_3]. Your plan is [plan_id_1]. Fetch all plans, critique the other two via plan_comment. Defend your plan or concede if another is genuinely better.`
- Resume Task 2 (task_id from planner 2): `Review all 3 plans: [plan_id_1], [plan_id_2], [plan_id_3]. Your plan is [plan_id_2]. Fetch all plans, critique the other two via plan_comment. Defend your plan or concede if another is genuinely better.`
- Resume Task 3 (task_id from planner 3): `Review all 3 plans: [plan_id_1], [plan_id_2], [plan_id_3]. Your plan is [plan_id_3]. Fetch all plans, critique the other two via plan_comment. Defend your plan or concede if another is genuinely better.`

Collect their critique summaries.

### User Checkpoint

Present a brief summary of each plan and the critiques to the user. Ask:

> The planners have critiqued each other's plans. Should they continue to a consensus round, or would you like to pick a winner yourself?

If the user picks one, skip to approval. Otherwise continue.

### Round 3 — Consensus (3 separate parallel agents, resumed)

You MUST call the Task tool exactly 3 times in a SINGLE message, resuming each planner's session using their `task_id`.

- Resume Task 1 (task_id from planner 1): `Read all comments on plans [plan_id_1], [plan_id_2], [plan_id_3]. You must reach consensus now. Either concede (transition your plan to abandoned) or argue yours is best. One plan must end in "reviewing" state, the others "abandoned". Return the winning plan_id and a markdown summary of the consensus plan.`
- Resume Task 2 (task_id from planner 2): same prompt
- Resume Task 3 (task_id from planner 3): same prompt

Collect results. Identify the winning plan_id (the one in `reviewing` state).

### User Approval

Present the consensus plan as formatted markdown. Ask the user to approve.

On approval, transition the winning plan to `approved` in the plan store.

### Round 4 — Implementation

Dispatch `regression-writer` with prompt:

`Implement the approved regression test plan. plan_id=<winning_plan_id>`

Return the writer's results to the user.

## Rules

- Always run Round 1 tasks in parallel (3 simultaneous Task calls).
- Always run Round 2 tasks in parallel.
- Always run Round 3 tasks in parallel.
- Wait for user input at the checkpoint before proceeding.
- Wait for user approval before dispatching the writer.
- If any agent returns an error, surface it and ask the user how to proceed.
- Do not skip rounds unless the user explicitly says to.

Context: $ARGUMENTS
