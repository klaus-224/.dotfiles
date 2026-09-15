#!/usr/bin/env bash
set -euo pipefail

fail() { printf '%s\n' "$*" >&2; exit 1; }
(( $# <= 1 )) || fail "Usage: open-github.sh [pane-id]"
pane="${1:-${TMUX_PANE:-}}"
[[ -n "$pane" ]] || fail "No tmux pane specified"
cwd=$(tmux display-message -p -t "$pane" '#{pane_current_path}') || fail "Cannot read pane directory"
[[ -d "$cwd" ]] || fail "Pane directory is unavailable"
url=$(git -C "$cwd" remote get-url origin) || fail "No origin remote in pane repository"

case "$url" in
    git@github.com:*) path=${url#git@github.com:} ;;
    ssh://git@github.com/*) path=${url#ssh://git@github.com/} ;;
    https://github.com/*) path=${url#https://github.com/} ;;
    *) fail "Origin must use github.com HTTPS or SSH" ;;
esac
path=${path%.git}
# Only repository paths, never credentials, query strings or lookalike hosts.
[[ "$path" =~ ^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$ ]] || fail "Invalid GitHub repository path"
[[ "$path" != */. && "$path" != */.. && "$path" != ./* && "$path" != ../* ]] || fail "Invalid GitHub repository path"
open "https://github.com/$path" || fail "Could not open GitHub"
