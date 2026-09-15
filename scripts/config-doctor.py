#!/usr/bin/env python3
"""Read-only checkout audit. Never execute discovered tools or read user data."""

import argparse
import json
import os
from pathlib import Path
import re
import shutil
import sys


REQUIRED = {
    "git": "repository and hook checks",
    "just": "validation recipes",
    "python3": "doctor and isolated validation",
    "zsh": "shell syntax and startup checks",
    "shellcheck": "supported-shell lint",
    "node": "OpenCode offline tests and typecheck",
}
OPTIONAL = {
    "nix": "explicit Nix evaluation/build (not part of offline validation)",
    "nvim": "sqb editor",
    "sqls": "work SQL LSP; personal uses postgres-language-server instead",
    "postgres-language-server": "personal SQL LSP; work uses sqls instead",
    "ctx7": "documentation lookup; manually provision npm package ctx7",
    "agent_memory": "private optional helper; not supplied by this repository",
    "session_reader": "private optional helper; not supplied by this repository",
    "fzf": "interactive session/navigation helpers",
    "tmux": "terminal sessions",
    "jq": "JSON helpers",
    "gh": "GitHub helpers (authentication not checked)",
    "starship": "optional shell prompt",
}


def managed_links(root):
    text = (root / "nix/home.nix").read_text()
    links = {}
    section = None
    for line in text.splitlines():
        if "xdg.configFile = {" in line:
            section = ".config/"
        elif "home.file = {" in line:
            section = ""
        match = re.search(r'^\s*(?:"([^"]+)"|([\w-]+))\.source = link "([^"]+)";', line)
        if match and section is not None:
            links[section + (match[1] or match[2])] = match[3]
    return links


def references(root):
    """Only known tracked config formats; never inspect local config or databases."""
    links = managed_links(root)
    for target, source in links.items():
        yield source, f"Home Manager {target}"
    for name in ("personal", "work"):
        profile = root / f"opencode/opencode.{name}.jsonc"
        if not profile.is_file():
            yield str(profile.relative_to(root)), "OpenCode profile"
            continue
        for source in file_references(profile.read_text()):
            yield str(Path("opencode") / source), str(profile.relative_to(root))
    for source in ("starship/starship.toml", "git/gh-dash/config.yml",
                   "ripgrep/.ripgreprc", "glow/vague.json",
                   "zsh/.zshenv", "zsh/.zshrc", "git/.gitignore.global"):
        yield source, "shell/config reference"


def file_references(text):
    # Recognize strings before comments, so URLs and escaped quotes remain intact.
    # This is a reference scan, not a replacement for OpenCode's JSONC validation.
    tokens = re.finditer(r'"(?:\\.|[^"\\])*"|//[^\n]*|/\*[\s\S]*?\*/', text)
    for token in tokens:
        if token[0].startswith('"'):
            yield from re.findall(r'\{file:([^}]+)\}', json.loads(token[0]))


def audit(root, *, refs_only=False, deployed_home=None):
    failures = 0

    def report(ok, detail, optional=False):
        nonlocal failures
        level = "OK" if ok else "WARN" if optional else "FAIL"
        print(f"{level}: {detail}")
        failures += int(not ok and not optional)

    if not (root / "nix/home.nix").is_file() or not (root / "Justfile").is_file():
        report(False, f"not a dotfiles checkout: {root}")
        return 1
    print(f"Checkout: {root}")
    if not refs_only:
        for tools, optional in ((REQUIRED, False), (OPTIONAL, True)):
            for name, purpose in tools.items():
                found = shutil.which(name)
                report(bool(found), f"{name}: {found or 'missing'} — {purpose}", optional)
        for name in ("tsx", "typescript", "@opencode-ai/plugin", "jsonc-parser", "ajv"):
            report((root / "opencode/node_modules" / name).is_dir(),
                   f"OpenCode dependency {name} (install separately from the reviewed lockfile)")
    for source, owner in references(root):
        path = root / source
        inside = path.resolve().is_relative_to(root.resolve())
        report(inside and path.exists(), f"{owner} -> {source}")
    links = managed_links(root)
    report(bool(links), "Home Manager live-link declarations found")
    report(".local/bin" not in links, "~/.local/bin is not managed as an entire directory")
    report((root / "bin").is_dir(), "managed bin source directory exists")
    for path in sorted((root / "bin").iterdir()) if (root / "bin").is_dir() else []:
        report(links.get(f".local/bin/{path.name}") == f"bin/{path.name}",
               f"individual managed link for bin/{path.name}")
        report(path.is_file() and os.access(path, os.X_OK), f"executable bin/{path.name}")
    if deployed_home is not None:
        print(f"Deployed link metadata only: {deployed_home}")
        report(not (deployed_home / ".local/bin").is_symlink(),
               "deployed ~/.local/bin must be a real directory before individual-link migration",
               optional=True)
        for target, source in links.items():
            path = deployed_home / target
            report(path.is_symlink() and path.resolve() == (root / source).resolve(),
                   f"deployed {target} points to this checkout's {source}", optional=True)
    print(f"Doctor: {failures} failure(s); warnings are optional or deployment-only.")
    return int(failures != 0)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--repo", type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument("--refs-only", action="store_true")
    parser.add_argument("--deployed-home", type=Path,
                        help="opt-in link metadata check; never source deployed files")
    args = parser.parse_args()
    return audit(args.repo.resolve(), refs_only=args.refs_only,
                 deployed_home=args.deployed_home)


if __name__ == "__main__":
    sys.exit(main())
