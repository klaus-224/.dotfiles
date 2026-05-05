#!/usr/bin/env -S uv run --script
# /// script
# ///

import json
import pathlib
import re

ROOT = pathlib.Path(".")
OUT = ROOT / ".repo-map"

IGNORE_DIRS = {
    ".git",
    "node_modules",
    ".venv",
    "dist",
    "build",
    "__pycache__"
}

ENTRYPOINT_PATTERNS = [
    r"if __name__ == ['\"]__main__['\"]",
    r"app\.listen",
    r"FastAPI\(",
    r"create_app",
    r"main\("
]

IMPORT_PATTERNS = [
    r"import ([a-zA-Z0-9_\.]+)",
    r"from ([a-zA-Z0-9_\.]+) import",
    r"require\(['\"](.*?)['\"]\)",
    r"import .* from ['\"](.*?)['\"]"
]


def is_ignored(path):
    return any(p in IGNORE_DIRS for p in path.parts)


def collect_files():
    files = []
    for p in ROOT.rglob("*"):
        if p.is_file() and not is_ignored(p):
            files.append(p)
    return files


def detect_stack(files):
    stack = {
        "languages": set(),
        "frameworks": set(),
    }

    for f in files:

        if f.suffix == ".py":
            stack["languages"].add("python")

        if f.suffix in {".js", ".ts"}:
            stack["languages"].add("javascript")

        if f.name == "package.json":
            stack["frameworks"].add("node")

        if f.name == "pyproject.toml":
            stack["frameworks"].add("python-project")

    return {k: list(v) for k, v in stack.items()}


def find_entrypoints(files):
    entrypoints = []

    for f in files:
        try:
            text = f.read_text(errors="ignore")
        except:
            continue

        for pattern in ENTRYPOINT_PATTERNS:
            if re.search(pattern, text):
                entrypoints.append(str(f))
                break

    return entrypoints


def build_dependency_graph(files):
    modules = []
    deps = []

    for f in files:

        if f.suffix not in {".py", ".ts", ".js"}:
            continue

        module = f.stem

        modules.append({
            "name": module,
            "path": str(f)
        })

        try:
            text = f.read_text(errors="ignore")
        except:
            continue

        for pattern in IMPORT_PATTERNS:
            matches = re.findall(pattern, text)

            for m in matches:
                deps.append({
                    "from": module,
                    "to": m
                })

    return modules, deps


def write_json(name, data):
    OUT.mkdir(exist_ok=True)

    with open(OUT / name, "w") as f:
        json.dump(data, f, indent=2)


def write_graphviz(modules, deps):
    OUT.mkdir(exist_ok=True)

    dot_file = OUT / "dependency-graph.dot"

    with open(dot_file, "w") as f:
        f.write("digraph repo {\n")
        f.write("  rankdir=LR;\n")
        f.write("  node [shape=box];\n")

        # nodes
        for m in modules:
            name = m["name"]
            f.write(f'  "{name}";\n')

        # edges
        for d in deps:
            src = d["from"]
            dst = d["to"]

            if src and dst:
                f.write(f'  "{src}" -> "{dst}";\n')

        f.write("}\n")


def main():

    files = collect_files()

    modules, deps = build_dependency_graph(files)
    entrypoints = find_entrypoints(files)
    stack = detect_stack(files)

    write_json("files.json", [str(f) for f in files])
    write_json("modules.json", modules)
    write_json("entrypoints.json", entrypoints)

    write_json("graph.json", {
        "modules": modules,
        "dependencies": deps
    })

    write_json("stack.json", stack)

    write_graphviz(modules, deps)

    print("Repo index generated in .repo-map/")


if __name__ == "__main__":
    main()
