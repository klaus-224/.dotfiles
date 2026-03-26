function explore() {
	local db_dir="${CODEX_REPO_DB_DIR:-$HOME/.codex/sqlite}"
	local uv_cache_dir="${UV_CACHE_DIR:-$db_dir/uv-cache}"
	mkdir -p "$db_dir" "$uv_cache_dir"

	CODEX_REPO_DB_DIR="$db_dir" UV_CACHE_DIR="$uv_cache_dir" codex exec \
		--profile repo-explorer \
		--add-dir "$db_dir" \
		-C "${1:-$PWD}" \
		"Explore this repository and produce an architecture summary."
}
