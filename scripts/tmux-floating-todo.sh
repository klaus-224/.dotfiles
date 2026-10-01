#!/usr/bin/env zsh

set -euo pipefail

TODO_FILE="${TODO_FILE:-$HOME/.local/share/todo.md}"
EDITOR="${EDITOR:-nvim}"

mkdir -p "$(dirname "$TODO_FILE")"
touch "$TODO_FILE"

tmux display-popup \
  -E \
  -x R \
  -y P \
  -w 40% \
  -h 60% \
  -d "$HOME" \
  "$EDITOR '$TODO_FILE'"
