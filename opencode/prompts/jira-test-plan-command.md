Create a manual test plan for: $ARGUMENTS

Interpret the input as a Jira key or issue URL, with optional GitHub PR URLs,
repository hints, or test-environment context. If it is empty, ask for the ticket.

Follow the ticket-review workflow: retrieve Jira context through Atlassian MCP,
delegate PR analysis to pr-review, then pass the completed findings and Jira
evidence to test-planner. Wait for its manual test plan and display the full plan
in this conversation, including numbered steps and expected results.
Stop after delivering it.
