#!/usr/bin/env bash
set -euo pipefail

DOTFILES_HOME="${DOTFILES_HOME:-"$HOME/.dotfiles/"}"

ln "$DOTFILES_HOME/ripgrep/.ripgreprc" "$HOME/.ripgreprc"
ln -sf "$DOTFILES_HOME/lazygit/config.yml" "$HOME/Library/Application\ Support/lazygit/config.yml"
