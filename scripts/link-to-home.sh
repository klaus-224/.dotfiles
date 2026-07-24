#!/usr/bin/env bash
set -euo pipefail

DOTFILES_HOME="${DOTFILES_HOME:-"$HOME/.dotfiles/"}"

ln "$DOTFILES_HOME/ripgrep/.ripgreprc" "$HOME/.ripgreprc" 
