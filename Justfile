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

# Build the Rust scripts and install them into ~/.local/bin
install-scripts:
    #!/usr/bin/env bash
    set -euo pipefail
    bin="$HOME/.local/bin"
    # Older Home Manager generations linked ~/.local/bin into this checkout.
    # Replace the link with a real directory, keeping non-script entries.
    if [[ -L "$bin" ]]; then
        old="$(cd "$bin" && pwd -P)"
        rm "$bin"
        mkdir -p "$bin"
        for entry in "$old"/*; do
            [[ -e "$entry" && "$entry" != *.backup ]] && cp -RP "$entry" "$bin/"
        done
        echo "Replaced the ~/.local/bin link with a directory"
    fi
    cargo install --locked --force --path {{quote(repo / "scripts")}} --root "$HOME/.local"

# Lint and test the Rust scripts
check-scripts:
    cd scripts && cargo fmt --check && cargo clippy --all-targets -- -D warnings && cargo test

clean:
    nix-collect-garbage -d
    sudo nix-collect-garbage -d
    nix store optimise
