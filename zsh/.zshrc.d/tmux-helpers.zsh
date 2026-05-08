# --------------------------------------------------
# tmux-helpers.zsh
# Purpose:
#   Predefined tmux pane layouts.
# --------------------------------------------------

function tlayout() {
	if [[ -z "$TMUX" ]]; then
		echo "Error: not in a tmux session" >&2
		return 1
	fi

	local layout="${1:-}"
	case "$layout" in
		development) _tlayout_development ;;
		*) echo "Usage: tlayout <layout>\nAvailable: development" >&2; return 1 ;;
	esac
}

function _tlayout_development() {
	# left(25%) | center(50%) | right(25%)
	# center split vertically in half
	tmux split-window -h -p 75
	tmux split-window -h -p 33
	tmux select-pane -t 1
	tmux split-window -v -p 50
	tmux select-pane -t 0
}
