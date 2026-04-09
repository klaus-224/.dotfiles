# OpenCode collaborative plan store

Reference implementation for a DB-backed planning workflow where specialized planning/review/execution agents collaborate through SQLite instead of committing transient markdown plans.

## Layout

- `schema.sql` — SQLite schema
- `plan_store.py` — Python CLI for managing plan state
- `plan.ts` — OpenCode custom tools wrapper
- `SKILL.md` — reusable skill instructions
- `code-planner.md`, `code-plan-reviewer.md`, `code-implementer.md` — example agents
- `opencode.snippets.jsonc` — optional config/command snippets

## Suggested install locations

Because OpenCode supports global agents, skills, and tools under `~/.config/opencode/`, a reusable setup can look like:

- `~/.config/opencode/bin/plan_store.py`
- `~/.config/opencode/tools/plan.ts`
- `~/.config/opencode/skills/plan-store/SKILL.md`
- `~/.config/opencode/agents/code-planner.md`
- `~/.config/opencode/agents/code-plan-reviewer.md`
- `~/.config/opencode/agents/code-implementer.md`

Initialize the database once:

```bash
mkdir -p ~/.local/state/opencode-plan-store
python3 ~/.config/opencode/bin/plan_store.py init-db
```

The DB path defaults to:

```bash
~/.local/state/opencode-plan-store/plans.db
```

Override it with:

```bash
export OPENCODE_PLAN_DB=/some/other/path/plans.db
```

## Typical flow

1. Planner creates a plan.
2. Planner claims the lease.
3. Planner revises the canonical JSON.
4. Reviewer reads the latest version and adds comments.
5. Reviewer transitions the plan to `reviewing` or back to `drafting`.
6. Once accepted, reviewer or planner approves a specific version.
7. Executor fetches the approved version and optionally renders markdown for a disposable handoff file.

## Plan JSON shape

```json
{
  "goal": "Implement feature X safely",
  "assumptions": ["No schema migration required"],
  "steps": [
    {
      "id": "step-1",
      "title": "Inspect current implementation",
      "status": "todo",
      "owner": "code-planner",
      "notes": []
    }
  ],
  "acceptance_criteria": ["Tests pass"],
  "validation": ["Run unit tests"],
  "touched_files": ["src/example.ts"],
  "risks": ["Edge case around null input"],
  "execution_notes": []
}
```

## Example direct CLI usage

```bash
python3 ~/.config/opencode/bin/plan_store.py create   --task-key feature/auth-refresh   --title "Add auth refresh flow"   --agent code-planner   --goal "Design and approve an implementation plan for auth refresh"
```

```bash
python3 ~/.config/opencode/bin/plan_store.py claim   --plan-id <PLAN_ID>   --agent code-planner   --ttl 900
```

```bash
cat plan.json | python3 ~/.config/opencode/bin/plan_store.py revise   --plan-id <PLAN_ID>   --agent code-planner   --change-note "Initial draft"   --stdin
```

```bash
python3 ~/.config/opencode/bin/plan_store.py approve   --plan-id <PLAN_ID>   --agent code-plan-reviewer
```

```bash
python3 ~/.config/opencode/bin/plan_store.py render   --plan-id <PLAN_ID>   --out /tmp/final-plan.md
```
