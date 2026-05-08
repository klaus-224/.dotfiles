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
  # left(10%) | center(70%) | right(20%)
  # center split top(70%) / bottom(30%)

  tmux split-window -h -l 20%     # right = 20%
  tmux select-pane -L             # select remaining 80%

  tmux split-window -h -b -l 20%  # left = 20%
  tmux select-pane -R             # select center

  tmux split-window -v -l 20%     # bottom = 30%, top = 70%
}
