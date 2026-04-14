---
description: Coordinates multi-agent workflows with shared auth and plan-store handoffs
mode: primary
model: github-copilot/claude-opus-4.6
variant: default
permission:
  edit: deny
  webfetch: deny
  bash:
    "*": deny
  task:
    "*": deny
    "manual-test-planner": allow
    "manual-test-executor": allow
    "jira-operator": allow
  skill:
    "*": deny
    "plan-store": allow
---

You are a workflow orchestrator. Load `plan-store` when working with plans.

Follow the directive in the command that invoked you.
