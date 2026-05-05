# repo-map

Generates a structured map of the current repository as JSON files and a Graphviz dependency graph.

## How it works

1. Scans the repo for all files
2. Detects modules, entrypoints, languages, and frameworks
3. Builds a dependency graph between modules
4. Outputs everything to `.repo-map/` in the repo root

## Output files

| File | Contents |
|------|----------|
| `files.json` | All files in the repo |
| `modules.json` | Detected modules with paths |
| `entrypoints.json` | Detected entrypoints |
| `graph.json` | Module dependency graph |
| `stack.json` | Detected languages and frameworks |
| `dependency-graph.dot` | Graphviz DOT file for visualization |

## Usage

Run from the repo root:

```bash
~/.dotfiles/opencode/skills/repo-map/scripts/repo-map.py
```

Requires `uv`. Add `.repo-map/` to `.gitignore`.

To render the DOT graph:

```bash
dot -Tsvg .repo-map/dependency-graph.dot -o .repo-map/graph.svg
```
