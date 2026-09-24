#!/usr/bin/env bash
set -uo pipefail

if (( $# == 0 )); then
  printf 'Usage: bash %s <ticket-url> [ticket-url ...]\n' "$0" >&2
  exit 1
fi

command -v opencode >/dev/null 2>&1 || {
  printf 'Error: opencode is not installed or not on PATH.\n' >&2
  exit 1
}

links=("$@")
log_dir="$(mktemp -d "${TMPDIR:-/tmp}/ticket-reviews.XXXXXX")" || exit 1
pids=()

printf 'Logs: %s\n' "$log_dir"

for i in "${!links[@]}"; do
  printf 'Starting: %s\n' "${links[$i]}"

  opencode run \
    --agent ticket-review \
    --title "Review ${links[$i]}" \
    "Review this ticket: ${links[$i]}" \
    </dev/null >"$log_dir/review-$i.log" 2>&1 &

  pids+=("$!")
done

status=0

for i in "${!pids[@]}"; do
  if wait "${pids[$i]}"; then
    printf 'Completed: %s\n' "${links[$i]}"
  else
    printf 'Failed: %s (see %s/review-%s.log)\n' \
      "${links[$i]}" "$log_dir" "$i" >&2
    status=1
  fi
done

exit "$status"
