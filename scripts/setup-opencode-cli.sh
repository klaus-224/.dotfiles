#!/usr/bin/env bash
set -euo pipefail

DOTFILES_HOME="${DOTFILES_HOME:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
OPENCODE_CONFIG_DIR="${OPENCODE_CONFIG_DIR:-$DOTFILES_HOME/opencode}"

export DOTFILES_HOME
export OPENCODE_CONFIG_DIR

if [[ ! -d "$OPENCODE_CONFIG_DIR" ]]; then
  echo "Error: missing OpenCode configuration directory: $OPENCODE_CONFIG_DIR" >&2
  exit 1
fi

for required in \
  opencode.work.jsonc \
  opencode.personal.jsonc \
  oh-my-opencode-slim.jsonc \
  package.json; do
  if [[ ! -f "$OPENCODE_CONFIG_DIR/$required" ]]; then
    echo "Error: missing $OPENCODE_CONFIG_DIR/$required" >&2
    exit 1
  fi
done

if ! command -v brew >/dev/null 2>&1; then
  echo "Error: Homebrew is required to install OpenCode." >&2
  exit 1
fi

if ! command -v opencode >/dev/null 2>&1; then
  echo "Installing OpenCode..."
  brew install opencode
fi

echo "Installing local OpenCode tool dependencies..."
npm install --prefix "$OPENCODE_CONFIG_DIR" --ignore-scripts

echo "OpenCode setup ready:"
echo "  DOTFILES_HOME=$DOTFILES_HOME"
echo "  OPENCODE_CONFIG_DIR=$OPENCODE_CONFIG_DIR"
echo "  Work profile: $OPENCODE_CONFIG_DIR/opencode.work.jsonc"
echo "  Personal profile: $OPENCODE_CONFIG_DIR/opencode.personal.jsonc"
echo "Source $DOTFILES_HOME/zsh/.zshenv before launching OpenCode."
