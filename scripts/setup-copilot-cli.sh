#!/usr/bin/env bash
set -euo pipefail

DOTFILES_HOME="${DOTFILES_HOME:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
COPILOT_HOME="${COPILOT_HOME:-$HOME/.copilot}"
COPILOT_CONFIG_FILE="${COPILOT_CONFIG_FILE:-$COPILOT_HOME/config.json}"
COPILOT_MCP_CONFIG_FILE="${COPILOT_MCP_CONFIG_FILE:-$COPILOT_HOME/mcp-config.json}"
AGENTS_DIR="$DOTFILES_HOME/agents"
COPILOT_STOW_PKG=".copilot"

export DOTFILES_HOME
export COPILOT_HOME
export COPILOT_CONFIG_FILE
export COPILOT_MCP_CONFIG_FILE

if ! command -v brew >/dev/null 2>&1; then
  echo "Error: Homebrew is required to install Copilot CLI." >&2
  exit 1
fi

if ! command -v stow >/dev/null 2>&1; then
  echo "Installing GNU stow..."
  brew install stow
fi

if [[ ! -d "$AGENTS_DIR/$COPILOT_STOW_PKG" ]]; then
  echo "Error: missing $AGENTS_DIR/$COPILOT_STOW_PKG" >&2
  exit 1
fi

echo "Installing Copilot CLI..."
brew install copilot-cli

mkdir -p "$COPILOT_HOME"

echo "Stowing Copilot config into $COPILOT_HOME..."
stow --verbose --restow --adopt --dir "$AGENTS_DIR" --target "$COPILOT_HOME" "$COPILOT_STOW_PKG"

echo "Copilot setup ready:"
echo "  DOTFILES_HOME=$DOTFILES_HOME"
echo "  COPILOT_HOME=$COPILOT_HOME"
echo "  COPILOT_CONFIG_FILE=$COPILOT_CONFIG_FILE"
echo "  COPILOT_MCP_CONFIG_FILE=$COPILOT_MCP_CONFIG_FILE"
