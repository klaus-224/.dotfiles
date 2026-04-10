---
description: Start Jira manual-testing workflow
agent: manual-test-orchestrator
---

Start the Jira manual-testing workflow.

Steps:
1. If explicit ticket keys are provided, use only those keys.
2. If ticket keys are not provided, ask Jira for the tickets currently assigned to me, return the discovered list, and stop until I confirm the specific ticket keys to run.
3. Respect explicit auth instructions in `$ARGUMENTS`: `refresh auth` forces a refresh and `reuse auth` allows reusing the existing auth file without refresh.
4. Only after ticket scope is explicit, ensure shared auth exists at `apps/playwright-tests/.auth/dev.json` using the existing `secrets`-based auth flow when available.
5. Default to refreshing auth before execution unless I explicitly asked to reuse existing auth.
6. Do not run planning, execution, or Jira commenting unless ticket scope is explicit and auth is ready.
7. Create a new plan-store record per ticket for this run. Do not reuse prior runs unless I explicitly ask to continue a specific plan id.
8. Run one serial workflow per selected ticket in this order only: Jira context -> planner draft -> executor critique -> planner revision -> executor execution -> Jira comment.
9. If execution returns `auth-blocked`, rerun the shared auth flow once via `apps/playwright-tests/setup.spec.ts` and retry execution once for that ticket.
10. Process selected tickets one at a time while using the shared auth state.
11. Return a short summary with:
   - auth
   - discovered tickets
   - selected tickets
   - per-ticket final plan
   - per-ticket execution findings
   - per-ticket Jira comment status
   - next action

Context:
$ARGUMENTS
