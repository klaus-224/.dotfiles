#!/bin/bash
# switch a named group of AeroSpace workspaces
# TODO:
#   - don't hard code the arguments
#   - extend for built-in, single, and builtin + single monitor setups
set -euo pipefail

usage() {
  printf '%s\n' \
    'Usage: aerospace-group <group>' \
    'Groups: code, browse, music, slack, discord, teams, teams-call' \
    'Requires two connected displays and the accompanying workspace assignments.'
}

if [[ $# -eq 1 && ( "$1" == --help || "$1" == -h ) ]]; then
  usage
  exit 0
fi

if [[ $# -ne 1 ]]; then
  usage >&2
  exit 2
fi

# The last workspace receives keyboard focus.
case "$1" in
  code)       workspaces=(code-secondary code-main) ;;
  browse)     workspaces=(browse-secondary browse-main) ;;
  music)      workspaces=(music) ;;
  slack)      workspaces=(slack) ;;
  discord)    workspaces=(discord) ;;
  teams)      workspaces=(teams) ;;
  teams-call) workspaces=(teams teams-call) ;;
  *) printf 'aerospace-group: unknown group: %s\n' "$1" >&2; usage >&2; exit 2 ;;
esac

if command -v aerospace >/dev/null 2>&1; then
  aerospace_bin=$(command -v aerospace)
else
  printf 'aerospace-group: aerospace was not found; install it or add it to PATH.\n' >&2
  exit 127
fi

if ! monitors=$("$aerospace_bin" list-monitors --format '%{monitor-id}'); then
  printf 'aerospace-group: cannot query displays; check that AeroSpace is running.\n' >&2
  exit 1
fi

monitor_count=0

while IFS= read -r monitor; do
  [[ -z "$monitor" ]] || monitor_count=$((monitor_count + 1))
done <<< "$monitors"
if [[ "$monitor_count" -ne 2 ]]; then
  printf 'aerospace-group: expected two displays, found %s; no workspaces changed.\n' "$monitor_count" >&2
  exit 1
fi

for workspace in "${workspaces[@]}"; do
  if ! "$aerospace_bin" workspace "$workspace"; then
    printf 'aerospace-group: could not select %s; any earlier switch remains in effect.\n' "$workspace" >&2
    exit 1
  fi
done
