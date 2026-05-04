---
name: repo-map
description: >
  Generates a local repo map with file listings, module dependency graphs,
  entrypoints, and tech stack detection. Use when asked to map, visualize,
  or get a structural overview of a repository.
---

# Repo Map

Generate a structured map of the current repository as JSON files and a
Graphviz dependency graph.

## When to use

- When exploring a new repository for the first time
- When asked to map, visualize, or diagram the repository
- When asked about the tech stack or architecture
- When you need a dependency graph

## How to run

Execute from the repository root:

```bash
$OPENCODE_CONFIG_DIR/skills/repo-map/scripts/repo-map.py
```

Requires `uv`.

## Output

Creates a `.repo-map/` directory containing:

| File                    | Contents                               |
|-------------------------|----------------------------------------|
| files.json              | All files in the repo                  |
| modules.json            | Detected modules with paths            |
| entrypoints.json        | Detected entrypoints                   |
| graph.json              | Module dependency graph                |
| stack.json              | Detected languages and frameworks      |
| dependency-graph.dot    | Graphviz DOT file for visualization    |

After running the script, read the JSON files to answer the user's questions.
