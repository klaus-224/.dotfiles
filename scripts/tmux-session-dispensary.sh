#!/usr/bin/env bash

DIRS=(
    "$HOME"
    "$HOME/code"
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
        sk "${SKIM_THEME_SESSION[@]}"
    )
fi

[[ -n "$selected" ]] || exit 0

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
