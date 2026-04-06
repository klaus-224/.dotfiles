#!/usr/bin/env bash
set -euo pipefail

DOTFILES_HOME="${DOTFILES_HOME:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
OPENCODE_HOME="${OPENCODE_HOME:-$HOME/.opencode}"
AGENTS_DIR="$DOTFILES_HOME/agents"
OPENCODE_STOW_PKG=".opencode"

export DOTFILES_HOME
export OPENCODE_HOME

if ! command -v brew >/dev/null 2>&1; then
  echo "Error: Homebrew is required to install OpenCode." >&2
  exit 1
fi

if ! command -v stow >/dev/null 2>&1; then
  echo "Installing GNU stow..."
  brew install stow
fi

if [[ ! -d "$AGENTS_DIR/$OPENCODE_STOW_PKG" ]]; then
  echo "Error: missing $AGENTS_DIR/$OPENCODE_STOW_PKG" >&2
  exit 1
fi

echo "Installing OpenCode..."
brew install opencode

mkdir -p "$OPENCODE_HOME"

echo "Stowing OpenCode config into $OPENCODE_HOME..."
stow --verbose --restow --adopt --dir "$AGENTS_DIR" --target "$OPENCODE_HOME" "$OPENCODE_STOW_PKG"

echo "OpenCode setup ready:"
echo "  DOTFILES_HOME=$DOTFILES_HOME"
echo "  OPENCODE_HOME=$OPENCODE_HOME"
