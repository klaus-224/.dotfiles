#!/usr/bin/env bash
set -euo pipefail

DOTFILES_HOME="${DOTFILES_HOME:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"
CODEX_CONFIG_FILE="${CODEX_CONFIG_FILE:-$CODEX_HOME/config.toml}"
AGENTS_DIR="$DOTFILES_HOME/agents"
CODEX_STOW_PKG=".codex"
CODEX_SKILLS_STOW_PKG=".codex-skills"

export DOTFILES_HOME
export CODEX_HOME
export CODEX_CONFIG_FILE

if ! command -v brew >/dev/null 2>&1; then
  echo "Error: Homebrew is required to install Codex CLI." >&2
  exit 1
fi

if ! command -v stow >/dev/null 2>&1; then
  echo "Installing GNU stow..."
  brew install stow
fi

if [[ ! -d "$AGENTS_DIR/$CODEX_STOW_PKG" ]]; then
  echo "Error: missing $AGENTS_DIR/$CODEX_STOW_PKG" >&2
  exit 1
fi

echo "Installing Codex CLI..."
brew install codex

mkdir -p "$CODEX_HOME" "$CODEX_HOME/skills"
mkdir -p "$AGENTS_DIR/$CODEX_SKILLS_STOW_PKG"

if [[ ! -f "$AGENTS_DIR/$CODEX_STOW_PKG/config.toml" ]]; then
  if [[ -f "$CODEX_CONFIG_FILE" ]]; then
    cp "$CODEX_CONFIG_FILE" "$AGENTS_DIR/$CODEX_STOW_PKG/config.toml"
  else
    : > "$AGENTS_DIR/$CODEX_STOW_PKG/config.toml"
  fi
fi

echo "Stowing Codex config into $CODEX_HOME..."
stow --verbose --restow --adopt --dir "$AGENTS_DIR" --target "$CODEX_HOME" "$CODEX_STOW_PKG"

if find "$AGENTS_DIR/$CODEX_SKILLS_STOW_PKG" -mindepth 1 -maxdepth 1 | grep -q .; then
  echo "Stowing custom Codex skills into $CODEX_HOME/skills..."
  stow --verbose --restow --adopt --dir "$AGENTS_DIR" --target "$CODEX_HOME/skills" "$CODEX_SKILLS_STOW_PKG"
else
  echo "No custom Codex skills found in $AGENTS_DIR/$CODEX_SKILLS_STOW_PKG (skipping)."
fi

echo "Codex setup ready:"
echo "  DOTFILES_HOME=$DOTFILES_HOME"
echo "  CODEX_HOME=$CODEX_HOME"
echo "  CODEX_CONFIG_FILE=$CODEX_CONFIG_FILE"
