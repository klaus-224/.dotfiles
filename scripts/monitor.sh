#!/usr/bin/env bash
set -euo pipefail

session="monitor"

# monitor doesnt, create new session with layout. start btm in one, abtop in the other
if ! tmux has-session -t "=$session" 2>/dev/null; then
    tmux new-session -d \
        -s "$session" \
        -c "$HOME" \
        -n btm 'btm'

    # Split horizontally and start a server
    tmux split-window -h -t "$session:btm" 'abtop'
fi

if [[ -n "${TMUX:-}" ]]; then
    tmux switch-client -t "=$session"
else
    tmux attach-session -t "=$session"
fi
