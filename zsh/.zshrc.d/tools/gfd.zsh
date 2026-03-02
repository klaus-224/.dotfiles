# --------------------------------------------------
# mnemonic: [G]it [F]ile [D]iff
# Browse commits for a file with fzf, then open a
# side-by-side diff of the selected commit in neovim.
#
# Usage: gfd <file>
# --------------------------------------------------

function gfd() {
	if [ -z "$1" ]; then
		echo "Usage: gfd <file>"
		return 1
	fi

	local file="$1"

	if [ ! -f "$file" ]; then
		echo "Error: File '$file' not found"
		return 1
	fi

	local rel_file
	rel_file=$(git ls-files --full-name "$file")

	export GFD_FILE="$rel_file"
	local commit
	commit=$(git log --follow --oneline -- "$file" |
		fzf --height=80% \
			--preview "git show {1}:$GFD_FILE 2>/dev/null | bat --color=always --style=numbers --file-name=$GFD_FILE || echo "File not found in this commit"" \
			--preview-window=right:60% \
			--header="Select commit to diff against current version (ESC to cancel)" |
		awk '{print $1}')
	unset GFD_FILE

	if [ -n "$commit" ]; then
		local tmpfile
		tmpfile=$(mktemp "/tmp/gfd-XXXXXX")
		git show "${commit}:${rel_file}" >"$tmpfile"
		nvim -d "$tmpfile" "$file"
		rm -f "$tmpfile"
	else
		echo "No commit selected"
	fi
}
