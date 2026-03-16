function explore() {
	codex exec \
		--profile repo-explorer \
		--add-dir "$HOME/.codex/sqlite" \
		-C "${1:-$PWD}" \
		"Explore this repository and produce an architecture summary."
}
