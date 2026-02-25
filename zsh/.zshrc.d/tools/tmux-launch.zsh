# --------------------------------------------------
# mnemonic: [T]mux [L]aunch
# Create a tmux session with panes from a JSON config file.
#
# Config format (JSON array):
# [
#   { "command": "npm run dev", "name": "api", "dir": "/path/to/project" },
#   { "command": "cargo watch", "name": "backend" }
# ]
#
# - command:  the command to run in the pane
# - name:     pane title
# - dir:      working directory (optional, defaults to $PWD)
#
# Usage: tl <config.json> [session-name]
# --------------------------------------------------

function tl() {
  if [[ $# -lt 1 ]]; then
    echo "Usage: tl <config.json> [session-name]" >&2
    return 1
  fi

  local config_file="$1"
  local session_name="${2:-}"

  if [[ ! -f "$config_file" ]]; then
    echo "Error: file not found: $config_file" >&2
    return 1
  fi

  if ! command -v jq &>/dev/null; then
    echo "Error: jq is required but not installed" >&2
    return 1
  fi

  local count
  count=$(jq 'length' "$config_file")

  for (( i = 0; i < count; i++ )); do
    local cmd name dir
    cmd=$(jq -r ".[$i].command" "$config_file")
    name=$(jq -r ".[$i].name" "$config_file")
    dir=$(jq -r ".[$i].dir // empty" "$config_file")
    dir="${dir:-$PWD}"
    dir="${dir/#\~/$HOME}"
    dir=$(eval echo "$dir")

    if (( i == 0 )); then
      if [[ -n "$session_name" ]]; then
        tmux new-session -d -s "$session_name" -c "$dir"
      else
        tmux new-session -d -c "$dir"
        session_name=$(tmux display-message -p '#{session_name}')
      fi
      tmux send-keys -t "$session_name" "$cmd" Enter
      tmux select-pane -t "$session_name" -T "$name"
      echo "Created session '$session_name', pane '$name' → $cmd (in $dir)"
    else
      tmux split-window -t "$session_name" -c "$dir"
      tmux send-keys -t "$session_name" "$cmd" Enter
      tmux select-pane -t "$session_name" -T "$name"
      tmux select-layout -t "$session_name" tiled
      echo "  Pane '$name' → $cmd (in $dir)"
    fi
  done
}
