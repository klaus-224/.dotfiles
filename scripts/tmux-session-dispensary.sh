#!/usr/bin/env bash
set -euo pipefail
(( $# <= 1 )) || { printf '%s\n' 'Usage: tmux-session-dispensary.sh [directory]' >&2; exit 1; }

selected="$1"

[[ -n "$selected" ]] || exit 0
[[ -d "$selected" ]] || { printf 'Not a directory: %s\n' "$selected" >&2; exit 1; }

relative="${selected#"$HOME"/}"
[[ "$selected" == "$HOME" ]] && relative="home"

# code/foo and documents/foo remain distinct.
session_name=$(printf '%s' "$relative" | tr '/. :' '____')

if ! tmux has-session -t "=$session_name" 2>/dev/null; then
    tmux new-session -d \
        -s "$session_name" \
        -c "$selected"
fi

tmux switch-client -t "=$session_name"
