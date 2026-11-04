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

# Build sbar-helper (SketchyBar's Rust backend) into an ad-hoc signed app
# bundle, so macOS can grant it Location (Wi-Fi names) and Calendar access.
# Rebuilding changes the signature: macOS may ask for those again.
install-sketchybar-helper:
    #!/usr/bin/env bash
    set -euo pipefail
    src={{quote(repo / "sketchybar-helper")}}
    app="$HOME/.local/share/sketchybar-helper/SketchyBarHelper.app"
    cargo build --release --locked --manifest-path "$src/Cargo.toml"
    mkdir -p "$app/Contents/MacOS" "$HOME/.local/bin"
    cp "$src/Info.plist" "$app/Contents/Info.plist"
    cp "$src/target/release/sbar-helper" "$app/Contents/MacOS/sbar-helper"
    codesign --force --sign - "$app" >/dev/null
    ln -sf "$app/Contents/MacOS/sbar-helper" "$HOME/.local/bin/sbar-helper"
    echo "Installed $app"
    command -v sketchybar >/dev/null && sketchybar --reload || true

# Lint and test the SketchyBar helper and Lua config
check-sketchybar:
    cd sketchybar-helper && cargo fmt --check && cargo clippy --all-targets -- -D warnings && cargo test
    for f in sketchybar/*.lua sketchybar/helpers/*.lua sketchybar/items/*.lua sketchybar/tests/*.lua; do luac -p "$f"; done
    lua sketchybar/tests/layout.lua
