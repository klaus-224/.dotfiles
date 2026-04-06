# --------------------------------------------------
# today.zsh
# Purpose:
#   Daily list workflow for Jira -> markdown -> nvim.
# --------------------------------------------------

# Remove a legacy alias after all zsh fragments are sourced.
# This keeps `today` available as a function even if an alias is defined later.
autoload -Uz add-zsh-hook
function _today_unalias_legacy_once() {
	if alias today >/dev/null 2>&1; then
		unalias today 2>/dev/null
	fi
	add-zsh-hook -d precmd _today_unalias_legacy_once 2>/dev/null
}
add-zsh-hook precmd _today_unalias_legacy_once

function _today_lists_dir() {
	echo "${TODAY_LISTS_DIR:-$HOME/Documents/lists}"
}

function _today_date() {
	date +%F
}

function _today_file_for_date() {
	local day="$1"
	echo "$(_today_lists_dir)/${day}.md"
}

function _today_today_file() {
	_today_file_for_date "$(_today_date)"
}

function _today_legacy_file() {
	echo "$(_today_lists_dir)/today.md"
}

function _today_ensure_lists_dir() {
	mkdir -p "$(_today_lists_dir)"
}

function _today_link_legacy() {
	local today_file="$1"
	local legacy_file
	legacy_file="$(_today_legacy_file)"

	ln -sfn "$(basename "$today_file")" "$legacy_file"
}

function _today_bootstrap_file() {
	local file="$1"

	if [[ -f "$file" ]]; then
		return 0
	fi

	cat >"$file" <<EOT
# $(_today_date) Tasks


EOT
}

function _today_archive_legacy_internal() {
	local today_file legacy_file archive_target
	today_file="$(_today_today_file)"
	legacy_file="$(_today_legacy_file)"
	archive_target="$today_file"

	_today_ensure_lists_dir

	if [[ -L "$legacy_file" ]]; then
		_today_link_legacy "$today_file"
		return 0
	fi

	if [[ ! -f "$legacy_file" ]]; then
		return 0
	fi

	if [[ -e "$archive_target" ]]; then
		archive_target="$(_today_lists_dir)/$(_today_date)-$(date +%H%M%S).md"
	fi

	mv "$legacy_file" "$archive_target"
	echo "Archived: $legacy_file -> $archive_target"

	_today_link_legacy "$today_file"
}

function _today_archive_legacy() {
	local legacy_file
	legacy_file="$(_today_legacy_file)"

	if [[ ! -f "$legacy_file" && ! -L "$legacy_file" ]]; then
		echo "No today.md found in $(_today_lists_dir)"
		return 0
	fi

	_today_archive_legacy_internal
}

function _today_run_copilot_prompt() {
	local prompt="$1"
	local desired_profile active_profile profiles_dir

	desired_profile="${TODAY_COPILOT_PROFILE:-}"
	profiles_dir="${COPILOT_PROFILES_DIR:-$HOME/.copilot/profiles}"

	if [[ -f "$profiles_dir/.active" ]]; then
		active_profile="$(<"$profiles_dir/.active")"
	fi

	if [[ -n "$desired_profile" ]]; then
		if ! typeset -f cpro >/dev/null 2>&1; then
			echo "TODAY_COPILOT_PROFILE is set, but cpro is unavailable." >&2
			return 1
		fi
		if ! cpro load "$desired_profile" >&2; then
			echo "Unable to load Copilot profile: $desired_profile" >&2
			return 1
		fi
		active_profile="$desired_profile"
	elif [[ -z "$active_profile" ]] && typeset -f cpro >/dev/null 2>&1; then
		if ! cpro load jira-agent >&2; then
			echo "Unable to load fallback Copilot profile: jira-agent" >&2
			return 1
		fi
		active_profile="jira-agent"
	fi

	if [[ -n "$TODAY_COPILOT_CMD" ]]; then
		[[ -n "$active_profile" ]] && echo "Using Copilot profile: $active_profile" >&2
		echo "Running Copilot prompt..." >&2
		"$TODAY_COPILOT_CMD" -p "$prompt" --add-dir "$(_today_lists_dir)"
		return $?
	fi

	if command -v copilot >/dev/null 2>&1; then
		[[ -n "$active_profile" ]] && echo "Using Copilot profile: $active_profile" >&2
		echo "Running Copilot prompt..." >&2
		copilot -p "$prompt" --add-dir "$(_today_lists_dir)"
		return $?
	fi

	echo "Copilot CLI not found. Install copilot-cli" >&2
	return 1
}

function _today_generate_from_jira() {
	local today_file prompt output tmp_output
	today_file="$(_today_today_file)"

	_today_ensure_lists_dir
	_today_archive_legacy_internal

	prompt="${TODAY_JIRA_PROMPT:-Query my Jira filter named \"My QC Tasks\" and generate a concise markdown plan for today. For each issue include key, short title and a link to the ticket. The list must be a todo list, and you should not add any of your thinking or steps to the markdown. Return ONLY markdown content.}"

	tmp_output="$(mktemp -t today-copilot-output.XXXXXX)" || {
		echo "Unable to create temporary output file." >&2
		return 1
	}

	if ! _today_run_copilot_prompt "$prompt" | tee "$tmp_output"; then
		rm -f "$tmp_output"
		echo "Copilot query failed. You can override with TODAY_COPILOT_CMD or TODAY_JIRA_PROMPT." >&2
		return 1
	fi

	output="$(<"$tmp_output")"
	rm -f "$tmp_output"

	if [[ -z "$output" ]]; then
		echo "Copilot returned empty output." >&2
		return 1
	fi

	printf "%s\n" "$output" >"$today_file"
	_today_link_legacy "$today_file"

	echo "Updated: $today_file"
}

function _today_open_file() {
	local file="$1"

	if ! command -v nvim >/dev/null 2>&1; then
		echo "nvim is required." >&2
		return 1
	fi

	nvim "$file"
}

function _today_open_today() {
	local today_file
	today_file="$(_today_today_file)"

	_today_ensure_lists_dir
	_today_archive_legacy_internal
	_today_bootstrap_file "$today_file"
	_today_link_legacy "$today_file"

	_today_open_file "$today_file"
}

function _today_fzf_files() {
	local selected

	if ! command -v fzf >/dev/null 2>&1; then
		echo "fzf is required. Install with: brew install fzf" >&2
		return 1
	fi

	_today_ensure_lists_dir

	selected=$(find "$(_today_lists_dir)" -maxdepth 1 -type f | sort |
		fzf --height=70% --layout=reverse --prompt='lists> ' \
			--preview 'bat --color=always -n {} 2>/dev/null || sed -n "1,200p" {}')

	[[ -z "$selected" ]] && return 0
	_today_open_file "$selected"
}

function today() {
	local cmd="${1:-open}"

	case "$cmd" in
	open)
		_today_open_today
		;;
	fetch | jira | sync)
		_today_generate_from_jira
		;;
	refresh)
		_today_generate_from_jira && _today_open_today
		;;
	archive)
		_today_archive_legacy
		;;
	path)
		_today_today_file
		;;
	files | list | fzf)
		_today_fzf_files
		;;
	help | -h | --help)
		cat <<'EOT'
Usage: today [command]

Commands:
  open      Open today's list in nvim (default)
  fetch     Generate today's file from Jira tasks via Copilot CLI
  refresh   Fetch from Jira, then open today's file
  archive   Archive legacy today.md to a date-based filename
  path      Print today's file path
  files     Browse all files in lists dir with fzf and open selection

Environment:
  TODAY_LISTS_DIR    Override lists directory (default: ~/Documents/lists)
  TODAY_COPILOT_CMD  Override copilot executable name/path (example: 'copilot')
  TODAY_COPILOT_PROFILE  Force cpro profile before running prompt
  TODAY_JIRA_PROMPT  Override the prompt sent to Copilot CLI
EOT
		;;
	*)
		echo "Unknown command: $cmd" >&2
		echo "Run: today help" >&2
		return 1
		;;
	esac
}
