---
description: Dispatch playwright-user agents to run through ui tests
agent: test-orchestrator
---

Reivew the user input test plan which should include multiple tests. For each test, dispatch a playwright-user agent perform manual
tests using the `playwright-cli`. The playwright-user agent should not need to manually authenticate, they just need to attach the browser context via
`playwright-cli state-load data/.auth/dev.json`. The agent does not need to submit a test plan either, they must simply execute the tests.

After all agents have completed, tell summarize the test results for the user including the tests conducted, and a pass/fail verdict
