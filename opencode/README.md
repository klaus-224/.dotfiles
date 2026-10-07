# OpenCode workflows

## Agents

| Agent | Mode | Purpose |
| --- | --- | --- |
| builder | Primary, default | Answer questions, implement changes, verify results, and finish tasks |
| chat | Primary, visible | Discuss and investigate without changing files |
| explore | Subagent | Investigate a bounded repository or documentation question |
| reviewer | Subagent | Review correctness and coverage and return actionable findings |

## Workflows

### Implementation and optional planning

Ask builder to implement directly, or use `/build-plan <outcome>` to plan through
Plannotator first. Select builder as the approval target when you want implementation.

```mermaid
flowchart TD
    Request[Task for builder] --> Planning{Plannotator planning requested?}
    Planning -- No --> Implement[Builder implements]
    Planning -- Yes --> Plan[Builder prepares a plan without editing]
    Plan --> Review[Review in Plannotator]
    Review --> Decision{Review decision}
    Decision -- Request changes --> Plan
    Decision -- Approve implementation --> Implement
    Decision -- Planning only --> PlanDone[Return approved plan]
    Decision -- Dismiss --> Stop[Stop without implementation]
    Implement --> Verify[Run relevant checks and review the diff]
    Verify --> Result[Report changes, results, and blockers]
```

### Manual test planning

Use `/manual-test-plan <ticket-or-context>` to prepare cases without running them.

```mermaid
flowchart LR
    Context[Ticket or supplied requirements] --> Evidence[Read requirements and associated PRs]
    Evidence --> Cases[Builder creates requirement-linked cases]
    Cases --> Plan[Return steps, expected results, and evidence gaps]
```

### Jira bug creation

Use `/bug <context>` in the work profile.

```mermaid
flowchart TD
    Context[Bug context] --> Intake[Collect details in the Plannotator form]
    Intake --> Draft[Prepare the team-template bug draft]
    Draft --> Authorized{Creation already authorized?}
    Authorized -- Yes --> Create[Create the Jira bug]
    Authorized -- No --> Review[Review the completed draft in Plannotator]
    Review --> Decision{Review decision}
    Decision -- Request changes --> Draft
    Decision -- Approve --> Create
    Decision -- Dismiss --> Stop[Keep draft without creating an issue]
    Create --> Link[Return the issue link]
```

### Manual test execution

Use `/manual-test <plan-or-ticket> <environment>` with an authorized test environment.

```mermaid
flowchart TD
    Input[Plan and test environment] --> Ready{Prerequisites available?}
    Ready -- No --> Blocked[Report BLOCKED and the missing prerequisite]
    Ready -- Yes --> Execute[Builder executes cases and captures evidence]
    Execute --> Outcome{Observed result}
    Outcome -- Matches expected --> Pass[Report PASS with evidence]
    Outcome -- Differs from expected --> Fail[Report FAIL with expected and actual results]
    Outcome -- Cannot complete --> Blocked
    Fail --> Draft[Prepare bug drafts for review]
```

### Playwright writing and review

Use `/pw-test <ticket-or-scope>` to add and run tests, or `/pw-review <PR-or-diff>`
for a read-only review.

```mermaid
flowchart TD
    Request[Playwright request] --> Mode{Write or review?}
    Mode -- Write --> Write[Builder adds tests using project fixtures]
    Write --> Run[Run targeted checks]
    Run --> Results[Report results, coverage gaps, and blockers]
    Mode -- Review --> Inspect[Reviewer inspects the PR or diff]
    Inspect --> Findings[Return prioritized correctness, coverage, and flakiness findings]
```

## Commands

| Command | Agent | Result |
| --- | --- | --- |
| `/build-plan <outcome>` | builder | Plannotator plan followed by approved implementation |
| `/manual-test-plan <ticket-or-context>` | builder | Requirement-linked manual cases |
| `/bug <context>` | builder | Work Jira bug draft and issue link after authorized creation |
| `/manual-test <plan-or-ticket> <environment>` | builder | PASS, FAIL, or BLOCKED for each case, with evidence |
| `/pw-test <ticket-or-scope>` | builder | Added tests and execution results |
| `/pw-review <PR-or-diff>` | reviewer | Prioritized findings and coverage gaps |
| `/plannotator-review` | builder | Interactive code review |
| `/plannotator-annotate <target>` | builder | Artifact annotations |
| `/plannotator-last` | builder | Annotations on the last response |

## Permissions

| Agent | Reads and lookup | File edits | Tests and evidence capture | Delegation | External writes | Unknown commands, installs, external directories |
| --- | --- | --- | --- | --- | --- | --- |
| builder | Allow | Allow | Allow configured checks; browser actions ask | explore, reviewer | Jira writes ask | Ask |
| chat | Allow | Deny | Deny | explore only | Deny | Deny |
| explore | Allow | Deny | Deny | Deny | Deny | Deny |
| reviewer | Allow | Deny | Deny | Deny | Deny | Deny |

| Boundary | All agents |
| --- | --- |
| Credential files | Deny; safe example files can be read |
| Pushes, destructive Git, history rewriting, blanket staging, hook bypasses | Deny |
| Jira deletion | Deny |
| Launching builder as a subagent | Deny |

## Plugins

| Plugin | Purpose |
| --- | --- |
| Plannotator | Review optional implementation plans, code, and artifacts |
| RTK | Reduce shell output and report token savings |
| PR context (personal) | Retrieve PR changes and evidence for selected test types |
