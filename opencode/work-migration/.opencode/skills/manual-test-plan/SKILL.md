---
name: manual-test-plan
description: Create evidence-backed manual test plans from Jira requirements and PR implementation reports. Use when ticket-review combines acceptance criteria, code changes, regression risks, and unresolved evidence into actionable manual checks.
---

# Manual test plan

Use Jira intent and a PR evidence report together. Preserve requirements when
implementation disagrees. Label inferred intent and unresolved expected behavior.

## Build actionable checks

- Give each scenario a stable ID `MT-01`, a descriptive title, and P0/P1/P2
  priority. Use P0 for critical authorization/data-loss/core-flow risks, P1 for
  required behavior and material regressions, P2 for lower-impact boundaries.
- Specify test data, role, environment, feature flags and starting state. Use
  explicit placeholders for unknown URLs/data; never invent credentials, labels,
  release states, or environment setup. Mark a scenario blocked when an unknown
  prevents reproducible steps or an authoritative expected result.
- Number the actions. State observable expected results at relevant steps and
  the final state. Include cleanup when a test changes persistent state.
- Cover happy paths, relevant edge/failure paths and affected existing behavior.
  Include permission boundaries only where the change or requirement warrants it.
- Map every explicit acceptance criterion to scenario IDs or a named gap. Map
  implementation-only behavior to a cited change/risk instead of inventing ACs.
- Separate requirements-only scenarios from code-supported scenarios. Do not
  claim coverage for unread diffs, inaccessible files, or missing comments.
- Keep manual checks manual. If a behavior needs timing instrumentation, internal
  assertions, load generation or unavailable access, describe the verification gap
  rather than inventing UI steps. Never execute the plan.

## Output

```markdown
# <KEY>: Manual Test Plan

Status: Ready for manual execution | Draft — missing evidence | Blocked
Execution: Not run

## Change summary
<Ticket intent, observed changes, and material differences.>

## Sources and scope
- Jira: <URL and retrieved/update time if available>
- PRs: <URLs, state, reviewed base/head SHAs>
- Evidence completeness: <complete/partial, stale snapshot or missing access>
- Included/excluded scope and dependencies: <details>

## Preconditions
<Environment/build, account roles, test data, flags, setup, and known unknowns.>
<Confirm the deployed build contains the reviewed changes before execution.>

## Acceptance criteria coverage
| Criterion | Requirement | Tests | Evidence or gap |
|---|---|---|---|
| AC-01 | ... | MT-01 | ... |

## Manual scenarios
### MT-01 — <title> [P1]
Basis: <AC IDs or change/risk; source links>
Status: Ready | Blocked — <reason>
Preconditions/data: <specific starting state>
Steps:
1. <action>
2. <action>
Expected results:
- <observable outcomes, tied to steps where useful>
Cleanup: <needed cleanup, or none>

## Review coverage
<Concise ledger of inspected, excluded, and unresolved changed files/areas.>

## Not manually verifiable
<Evidence-backed gaps; use None identified only when supported.>

## Risks and questions
<Conflicts, missing inputs, deployment uncertainty, blocked scenarios.>
```

Before returning, check every criterion is accounted for, scenarios have testable
outcomes, evidence links support their claims, and no result implies execution.
If PR review was unavailable, explicitly label the whole output a requirements-only
draft. Do not describe that plan as ready or complete.
