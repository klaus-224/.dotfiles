#!/usr/bin/env python3
"""Explicit, checkout-relative validators; no installers or activation commands."""

import argparse
from pathlib import Path
import re
import shutil
import subprocess
import sys


def run(root, command):
    print("+ " + " ".join(map(str, command)), flush=True)
    return subprocess.run(list(map(str, command)), cwd=root, check=False).returncode


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("check", choices=("zsh", "shellcheck", "opencode", "schema", "typecheck", "hooks"))
    parser.add_argument("--repo", type=Path, default=Path(__file__).resolve().parents[1])
    args = parser.parse_args()
    root = args.repo.resolve()
    commands = []
    if args.check in ("zsh", "shellcheck"):
        # Explicit source trees only: never visit node_modules, local.zsh or data.
        candidates = list((root / "bin").iterdir()) + list((root / "scripts").glob("*.sh"))
        candidates += list((root / "git/hooks").glob("*"))
        if args.check == "zsh":
            files = [root / "zsh/.zshenv", root / "zsh/.zshrc"]
            files += [p for p in (root / "zsh/.zshrc.d").glob("*.zsh") if p.name != "local.zsh"]
            commands += [["zsh", "-d", "-f", "-n", p] for p in sorted(files)]
        for path in sorted(candidates):
            if not path.is_file():
                continue
            with path.open() as source:
                first = source.readline().strip()
            match = re.fullmatch(r"#!(?:/usr/bin/env\s+|/(?:usr/)?bin/)(bash|sh|dash|ksh|zsh)(?:\s.*)?", first)
            if not match:
                continue
            shell = match[1]
            if args.check == "zsh" and shell == "zsh":
                commands.append(["zsh", "-d", "-f", "-n", path])
            elif args.check == "shellcheck" and shell != "zsh":
                commands.append(["shellcheck", "--norc", "--shell=" + shell, path])
    elif args.check in ("opencode", "schema"):
        tests = sorted((root / "opencode/tests").glob("*.test.ts"))
        tests = [p for p in tests if ("schema" in p.name) == (args.check == "schema")]
        if not tests:
            print("FAIL: no matching OpenCode tests", file=sys.stderr)
            return 1
        if not (root / "opencode/node_modules/tsx").is_dir():
            print("FAIL: local tsx dependency missing; provision reviewed dependencies separately", file=sys.stderr)
            return 1
        commands = [["node", "--import", "tsx", "--test", *tests]]
        root = root / "opencode"
    elif args.check == "typecheck":
        compiler = root / "opencode/node_modules/typescript/bin/tsc"
        if not compiler.is_file():
            print("FAIL: local TypeScript dependency missing; provision reviewed dependencies separately", file=sys.stderr)
            return 1
        commands = [["node", compiler, "--noEmit", "--incremental", "false", "--project", root / "opencode/tsconfig.json"]]
    else:
        # Hooks and terminal helpers use mocks; no commits or live sessions.
        test = root / "tests/git-terminal.test.mjs"
        if not test.is_file():
            print(f"FAIL: hook suite missing: {test}", file=sys.stderr)
            return 1
        commands = [["node", "--test", test]]
    failed = False
    for command in commands:
        if not shutil.which(command[0]):
            print(f"FAIL: {command[0]} is not on PATH", file=sys.stderr)
            failed = True
        else:
            failed = run(root, command) != 0 or failed
    return int(failed)


if __name__ == "__main__":
    sys.exit(main())
