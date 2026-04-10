withsecrets() {
	local entry="${SECRETS_ENTRY:-env/work}"
	local data
	data="$(pass show "$entry")" || return 1

	# Build env assignments safely
	local -a env_args
	local line
	while IFS= read -r line; do
		[[ -z "$line" || "$line" == \#* ]] && continue
		env_args+=("$line")
	done <<<"$data"

	env "${env_args[@]}" "$@"
}
