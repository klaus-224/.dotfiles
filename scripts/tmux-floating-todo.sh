#!/usr/bin/env zsh

set -euo pipefail

TODO_FILE="${TODO_FILE:-$HOME/.local/share/todo.md}"
EDITOR="${EDITOR:-nvim}"

mkdir -p "$(dirname "$TODO_FILE")"
touch "$TODO_FILE"

tmux display-popup \
  -E \
  -w 70% \
  -h 70% \
  -d "$HOME" \
  "$EDITOR '$TODO_FILE'"
