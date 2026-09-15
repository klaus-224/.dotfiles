#!/usr/bin/env bash
set -euo pipefail
(( $# <= 1 )) || { printf '%s\n' 'Usage: tmux-session-dispensary.sh [directory]' >&2; exit 1; }

DIRS=(
    "$HOME"
    "$HOME/code"
    "$HOME/code/sandbox/"
    "$HOME/documents"
)

if (( $# == 1 )); then
    selected="$1"
else
    selected=$(
        fd . "${DIRS[@]}" \
            --type directory \
            --max-depth 1 \
            --absolute-path |
        fzf
    ) || {
        status=$?
        # fzf uses 1 for no match and 130 for cancellation.
        [[ "$status" == 1 || "$status" == 130 ]] && exit 0
        exit "$status"
    }
fi

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
