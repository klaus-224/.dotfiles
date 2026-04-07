---
description: Run plan -> execute -> review
agent: workflow-orchestrator
---

Run the full workflow.

Steps:
1. Delegate planning to workflow-planner.
2. Summarize the plan briefly.
3. Delegate implementation to workflow-executor.
4. Delegate review to workflow-reviewer.
5. Return a short final summary with:
   - plan
   - execution
   - review
   - next action

Task: $ARGUMENTS
