# Regression Test Agent Learnings

This file points to a SQLite database of learnings accumulated by regression test agents across runs.

**Database:** `~/code/.agents/learnings.db`
**CLI:** `python3 ~/.dotfiles/opencode/bin/learnings.py`

## Categories

| Category | What goes here |
|----------|---------------|
| `navigation` | How to get to specific pages/states in the app, workarounds for navigation issues |
| `tool-usage` | When to use playwright-cli vs repo-query, why one tool worked better than another |
| `codebase` | Structural knowledge — where things live, naming conventions, import patterns |
| `gotcha` | Things that tripped the agent up — timing issues, race conditions, flaky selectors |
| `fixture` | Notes on existing fixtures — what they do, when to use them, limitations |
| `selector` | Which selectors work reliably, which are fragile, data-testid coverage gaps |
| `debugging` | How to get unstuck — common failures and their solutions |

## Example Queries

```bash
# Get all navigation tips
python3 ~/.dotfiles/opencode/bin/learnings.py query --category navigation

# Search for anything about "source panel"
python3 ~/.dotfiles/opencode/bin/learnings.py query --search "source panel"

# Get recent learnings from last run
python3 ~/.dotfiles/opencode/bin/learnings.py recent --limit 5

# Find gotchas tagged with "timing"
python3 ~/.dotfiles/opencode/bin/learnings.py query --category gotcha --tags timing

# Add a new learning
python3 ~/.dotfiles/opencode/bin/learnings.py add \
  --category gotcha \
  --summary "Dashboard fixture closes AI agent popup but it can reappear after navigation" \
  --detail "If you navigate away and back, the AI agent popup reappears. Use dashboard.closeAiAgent() again after navigation." \
  --tags "ai-agent,navigation,popup" \
  --agent "regression-writer"
```
