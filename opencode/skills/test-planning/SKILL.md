---
name: test-planning
description: Produce evidence-backed PR test scenarios without widening explicitly selected test categories.
---

# Test Planning

Use this skill only when a command supplies an explicit allowed test-type set. Never choose, infer, add, or recommend another category.

## Categories

- `manual`: A human-oriented procedure. Browser assistance may execute it later, but the scenario does not create a persisted automated suite.
- `unit`: An isolated automated check at the repository's established unit boundary. Do not silently include integration, component, end-to-end, or browser tests.
- `playwright`: A persisted Playwright test that follows the repository's existing test structure, fixtures, selector conventions, and authentication boundaries.

If changed behavior cannot be meaningfully covered by an allowed category, put it under coverage limitations with the code-backed reason. Do not substitute another category.

## Evidence

- Tie every scenario to changed behavior and repository evidence.
- Cite files, symbols, tests, fixtures, routes, or configuration; include lines when reliable.
- Track every changed file as inspected, mechanically excluded with a reason, or unresolved.
- Call out omitted GitHub patches, generated/binary files, truncated data, missing checkout context, and unavailable dependencies.
- Never claim complete analysis while any material file or patch remains unresolved.

## Scenario contract

Each scenario includes:

- stable ID scoped to the plan, such as `manual-01`, `unit-01`, or `playwright-01`,
- exactly one allowed test type,
- changed behavior and why it matters,
- preconditions/setup,
- ordered actions or implementation outline,
- observable expected results,
- source references,
- suggested test location when applicable.

Scenarios should be specific enough for review and later execution without inventing environment details. Prefer fewer grounded scenarios over broad checklists or duplicate permutations.

## Quality checks

Before returning a plan:

1. Confirm every scenario category belongs to the allowed set.
2. Confirm scenarios test changed behavior rather than restating changed files.
3. Confirm expected results are observable and distinguish pass from fail.
4. Confirm assumptions and unresolved evidence are visible.
5. Confirm manual and Playwright coverage are not conflated.
6. Confirm no implementation, test execution, publication, or approval authorization occurred.
