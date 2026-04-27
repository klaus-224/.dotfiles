# --------------------------------------------------
# smolvm.zsh
# Purpose:
#   Render smolvm config files from templates.
# --------------------------------------------------

function smolfile_render {
	local template="${1:?usage: smolfile_render TEMPLATE [OUTPUT]}"
	local output="${2:-${template%.tmpl}}"

	if [[ ! -f "$template" ]]; then
		print -u2 "smolfile_render: template not found: $template"
		return 1
	fi

	if ! command -v envsubst >/dev/null 2>&1; then
		print -u2 "smolfile_render: envsubst is required"
		print -u2 "install with: brew install gettext && brew link --force gettext"
		return 1
	fi

	: "${SMOLVM_WORKSPACE:?SMOLVM_WORKSPACE is not set}"

	mkdir -p "$SMOLVM_WORKSPACE" || return 1

	envsubst < "$template" > "$output" || return 1

	print "rendered: $output"
}
