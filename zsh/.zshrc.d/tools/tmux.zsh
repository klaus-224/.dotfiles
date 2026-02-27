# --------------------------------------------------
# START HELPERS
# --------------------------------------------------
function _check_in_tmux(){
    if ! command -v tmux &>/dev/null; then
        echo "Error: tmux is required but not installed" >&2
        return 1
    fi
}

function _check_duplicate_session(){
    local session_name="$1"

    if tmux has-session -t "$session_name" 2>/dev/null; then
        echo "Error: session already exists: $session_name" >&2
        return 1
    fi
}

function _check_duplicate_window(){
    local window_name="$1"
    if tmux has-window -t "$window_name" 2>/dev/null; then
        echo "Error: window already exists: $window_name" >&2
        return 1
    fi
}
# --------------------------------------------------
# END HELPERS
# --------------------------------------------------

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
    _check_in_tmux

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

# --------------------------------------------------
# mnemonic: tmux 3 windows (explorer/editor/agent)
# Usage: t3 [session-name]
# --------------------------------------------------
function t3() {
    local session_name="${1:-$(basename "$PWD")}"
    local workdir="$PWD"

    _check_duplicate_session "$session_name"

    if !command -v tmux &>/dev/null; then
        echo "Error: tmux is required but not installed" >&2
        return 1
    fi

    if tmux has-session -t "$session_name" 2>/dev/null; then
        echo "Error: session already exists: $session_name" >&2
        return 1
    fi

    tmux new-session -d -s "$session_name" -n "explorer" -c "$workdir"
    tmux send-keys -t "$session_name:explorer" "yazi" Enter

    tmux new-window -t "$session_name" -n "editor" -c "$workdir"
    tmux send-keys -t "$session_name:editor" "nvim" Enter

    tmux new-window -t "$session_name" -n "agent" -c "$workdir"
    tmux select-window -t "$session_name:explorer"

    if [[ -n "$TMUX" ]]; then
        tmux switch-client -t "$session_name"
    else
        tmux attach-session -t "$session_name"
    fi
}
