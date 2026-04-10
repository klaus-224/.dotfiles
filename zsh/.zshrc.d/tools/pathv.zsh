# --------------------------------------------------
# pathv.zsh
# Purpose:
#   Small fzf viewer for PATH entries.
# --------------------------------------------------

unalias pathv 2>/dev/null

function pathv {
	if ! command -v fzf >/dev/null 2>&1; then
		echo "fzf is required. Install with: brew install fzf" >&2
		return 1
	fi

	print -r -- "$PATH" |
		tr ':' '\n' |
		awk 'NF' |
		uniq |
		fzf --height=60% --layout=reverse --prompt='path> '
}
