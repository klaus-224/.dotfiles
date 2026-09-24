repo := justfile_directory()

default:
  @just --justfile {{quote(justfile())}} --list

rebuild:
    sudo darwin-rebuild switch --flake ~/.dotfiles/nix#klaus-macbook

rebuild-work:
    sudo darwin-rebuild switch --flake ~/.dotfiles/nix#work-macbook

update:
    cd nix && nix flake update
    sudo darwin-rebuild switch --flake ~/.dotfiles/nix#klaus-macbook

update-work:
    cd nix && nix flake update
    sudo darwin-rebuild switch --flake ~/.dotfiles/nix#work-macbook

clean:
    nix-collect-garbage -d
    sudo nix-collect-garbage -d
    nix store optimise

# Offline/default validation never evaluates Nix or fetches schemas.
check: validate

doctor:
    python3 -B {{quote(repo / "scripts/config-doctor.py")}} --repo {{quote(repo)}}

# Opt-in: inspect link metadata in the supplied home, not its contents.
doctor-deployed home:
    python3 -B {{quote(repo / "scripts/config-doctor.py")}} --repo {{quote(repo)}} --deployed-home {{quote(home)}}

validate: validate-refs validate-zsh validate-shellcheck validate-audit-tests validate-opencode validate-typecheck validate-hooks

validate-refs:
    python3 -B {{quote(repo / "scripts/config-doctor.py")}} --repo {{quote(repo)}} --refs-only

validate-zsh:
    python3 -B {{quote(repo / "scripts/config-validate.py")}} --repo {{quote(repo)}} zsh

validate-shellcheck:
    python3 -B {{quote(repo / "scripts/config-validate.py")}} --repo {{quote(repo)}} shellcheck

validate-audit-tests:
    python3 -B {{quote(repo / "scripts/test-config-audit.py")}}

validate-opencode:
    python3 -B {{quote(repo / "scripts/config-validate.py")}} --repo {{quote(repo)}} opencode

validate-typecheck:
    python3 -B {{quote(repo / "scripts/config-validate.py")}} --repo {{quote(repo)}} typecheck

validate-hooks:
    python3 -B {{quote(repo / "scripts/config-validate.py")}} --repo {{quote(repo)}} hooks

# Explicit Homebrew-runtime check; not part of the offline default validation.
validate-sketchybar:
    #!/bin/bash
    set -euo pipefail
    lua=/opt/homebrew/bin/lua
    luac=/opt/homebrew/bin/luac
    for executable in "$lua" "$luac"; do
      if [[ ! -x "$executable" ]]; then
        printf 'FAIL: required SketchyBar runtime is missing: %s\n' "$executable" >&2
        exit 1
      fi
    done
    while IFS= read -r file; do
      "$luac" -p "$file"
    done < <(printf '%s\n' \
      {{quote(repo / "sketchybar/sketchybarrc")}} \
      {{quote(repo / "sketchybar")}}/*.lua \
      {{quote(repo / "sketchybar/items")}}/*.lua \
      {{quote(repo / "tests/sketchybar.test.lua")}})
    bash -n {{quote(repo / "scripts/aerospace-groups.sh")}}
    shellcheck --norc --shell=bash {{quote(repo / "scripts/aerospace-groups.sh")}}
    CONFIG_DIR={{quote(repo / "sketchybar")}} "$lua" {{quote(repo / "tests/sketchybar.test.lua")}} {{quote(repo)}}

# Explicit network-only schema suite; never a dependency of validate.
validate-schema:
    python3 -B {{quote(repo / "scripts/config-validate.py")}} --repo {{quote(repo)}} schema

# Both hosts, no lock writes, no activation. May fetch inputs/write Nix caches.
validate-nix-eval:
    nix eval --no-update-lock-file --no-write-lock-file --raw {{quote("path:" + repo / "nix#darwinConfigurations.klaus-macbook.system.drvPath")}}
    nix eval --no-update-lock-file --no-write-lock-file --raw {{quote("path:" + repo / "nix#darwinConfigurations.work-macbook.system.drvPath")}}

# Explicit builds may download/build store paths; no result links or switch.
validate-nix-build:
    nix build --no-update-lock-file --no-write-lock-file --no-link {{quote("path:" + repo / "nix#darwinConfigurations.klaus-macbook.system")}} {{quote("path:" + repo / "nix#darwinConfigurations.work-macbook.system")}}
