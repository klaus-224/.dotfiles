#!/usr/bin/env zsh

set -euo pipefail

NOTES_FILE="${NOTES_FILE:-$HOME/Documents/notes.md}"
EDITOR="${EDITOR:-nvim}"

mkdir -p "$(dirname "$NOTES_FILE")"
touch "$NOTES_FILE"

tmux display-popup \
  -E \
  -w 70% \
  -h 70% \
  -d "$(dirname "$NOTES_FILE")" \
  "$EDITOR '$NOTES_FILE'"
