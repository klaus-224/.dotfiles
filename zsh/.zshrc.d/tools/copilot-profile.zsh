# --------------------------------------------------
# copilot-profile.zsh
# Purpose:
#   Manage named profiles for GitHub Copilot CLI.
#
# Function mnemonic: [C]opilot [PRO]file
#
# Usage:
#   cpro new-profile <name>   # create a profile directory
#   cpro load [name]          # load profile (no name = fzf picker)
#   cpro list                 # list saved profiles
#   cpro show [name]          # show profile contents (default: active)
#   cpro edit <name>          # open profile in $EDITOR
# --------------------------------------------------

_CPRO_HOME="${${COPILOT_HOME:-$HOME/.copilot}%/}"
_CPRO_DIR="${${COPILOT_PROFILES_DIR:-$_CPRO_HOME/profiles}%/}"
_CPRO_CONFIG="${COPILOT_CONFIG_FILE:-$_CPRO_HOME/config.json}"
_CPRO_MCP="${COPILOT_MCP_CONFIG_FILE:-$_CPRO_HOME/mcp-config.json}"
_CPRO_INSTRUCTIONS="$_CPRO_HOME/copilot-instructions.md"

_cpro_ensure_dir() { [[ -d "$_CPRO_DIR" ]] || mkdir -p "$_CPRO_DIR"; }

_cpro_check_jq() {
    if ! command -v jq >/dev/null 2>&1; then
        echo "Error: jq is required. Install with: brew install jq" >&2
        return 1
    fi
}

_cpro_active_name() {
    if [[ -f "$_CPRO_DIR/.active" ]]; then
        cat "$_CPRO_DIR/.active"
    else
        echo "(none)"
    fi
}

_cpro_profile_path() { printf '%s/%s' "$_CPRO_DIR" "$1"; }

_cpro_list_names() {
    _cpro_ensure_dir
    local active
    active="$(_cpro_active_name)"
    for dir in "$_CPRO_DIR"/*(N/); do
        local name="${dir:t}"
        if [[ "$name" == "$active" ]]; then
            printf '* %s\n' "$name"
        else
            printf '  %s\n' "$name"
        fi
    done
}

_cpro_new_profile() {
    local name="$1"
    if [[ -z "$name" ]]; then
        echo "Usage: cpro new-profile <name>" >&2
        return 1
    fi
    _cpro_ensure_dir
    local dest="$(_cpro_profile_path "$name")"
    if [[ -d "$dest" ]]; then
        echo "Error: profile '$name' already exists." >&2
        return 1
    fi
    mkdir -p "$dest"
    if [[ -f "$_CPRO_CONFIG" ]]; then
        cp "$_CPRO_CONFIG" "$dest/config.json"
    else
        echo '{}' > "$dest/config.json"
    fi
    if [[ -f "$_CPRO_MCP" ]]; then
        cp "$_CPRO_MCP" "$dest/mcp-config.json"
    else
        echo '{"mcpServers":{}}' > "$dest/mcp-config.json"
    fi
    if [[ -f "$_CPRO_INSTRUCTIONS" ]]; then
        cp "$_CPRO_INSTRUCTIONS" "$dest/copilot-instructions.md"
    fi
    echo "Profile '$name' created at $dest."
}

_cpro_load() {
    local name="$1"
    if [[ -z "$name" ]]; then
        _cpro_pick
        return $?
    fi

    _cpro_ensure_dir
    local src="$(_cpro_profile_path "$name")"
    if [[ ! -d "$src" ]]; then
        echo "Error: profile '$name' not found." >&2
        return 1
    fi
    if [[ ! -f "$src/config.json" || ! -f "$src/mcp-config.json" ]]; then
        echo "Error: profile '$name' is missing config.json or mcp-config.json." >&2
        return 1
    fi

    ln -sfn "$src/config.json" "$_CPRO_CONFIG"
    ln -sfn "$src/mcp-config.json" "$_CPRO_MCP"
    if [[ -f "$src/copilot-instructions.md" ]]; then
        ln -sfn "$src/copilot-instructions.md" "$_CPRO_INSTRUCTIONS"
        echo "Profile '$name' loaded (with instructions)."
    else
        [[ -L "$_CPRO_INSTRUCTIONS" ]] && rm -f "$_CPRO_INSTRUCTIONS"
        echo "Profile '$name' loaded."
    fi
    echo "$name" > "$_CPRO_DIR/.active"
}

_cpro_show() {
    local name="${1:-$(_cpro_active_name)}"
    if [[ "$name" == "(none)" ]]; then
        echo "── active config (no profile loaded) ──"
        echo "config.json:"
        jq '.' "$_CPRO_CONFIG"
        echo "\nmcp-config.json:"
        jq '.' "$_CPRO_MCP"
        if [[ -e "$_CPRO_INSTRUCTIONS" ]]; then
            echo "\ncopilot-instructions.md:"
            cat "$_CPRO_INSTRUCTIONS"
        fi
        return
    fi

    local src="$(_cpro_profile_path "$name")"
    if [[ ! -d "$src" ]]; then
        echo "Error: profile '$name' not found." >&2
        return 1
    fi
    echo "── profile: $name ──"
    echo "config.json:"
    jq '.' "$src/config.json"
    echo "\nmcp-config.json:"
    jq '.' "$src/mcp-config.json"
    if [[ -f "$src/copilot-instructions.md" ]]; then
        echo "\ncopilot-instructions.md:"
        cat "$src/copilot-instructions.md"
    fi
}

_cpro_edit() {
    local name="$1"
    if [[ -z "$name" ]]; then
        echo "Usage: cpro edit <name>" >&2
        return 1
    fi
    local src="$(_cpro_profile_path "$name")"
    if [[ ! -d "$src" ]]; then
        echo "Error: profile '$name' not found." >&2
        return 1
    fi
    local files=("$src/config.json" "$src/mcp-config.json")
    [[ -f "$src/copilot-instructions.md" ]] && files+=("$src/copilot-instructions.md")
    ${EDITOR:-nvim} "${files[@]}"
}

_cpro_pick() {
    _cpro_ensure_dir
    local profiles=()
    for dir in "$_CPRO_DIR"/*(N/); do
        profiles+=("${dir:t}")
    done
    if (( ${#profiles} == 0 )); then
        echo "No saved profiles. Use 'cpro new-profile <name>' to create one." >&2
        return 1
    fi
    if ! command -v fzf >/dev/null 2>&1; then
        echo "fzf is required for interactive selection. Use 'cpro load <name>' instead." >&2
        return 1
    fi

    local active choice
    active="$(_cpro_active_name)"
    choice=$(printf '%s\n' "${profiles[@]}" | \
        fzf --height=50% --layout=reverse \
            --prompt='Copilot Profile> ' \
            --header="Active: $active" \
            --preview="echo '── config.json ──' && jq -C '.' '$_CPRO_DIR/{}/config.json' 2>/dev/null && echo '' && echo '── mcp-config.json ──' && jq -C '.' '$_CPRO_DIR/{}/mcp-config.json' 2>/dev/null && if [[ -f '$_CPRO_DIR/{}/copilot-instructions.md' ]]; then echo '' && echo '── copilot-instructions.md ──' && cat '$_CPRO_DIR/{}/copilot-instructions.md'; fi")
    if [[ -n "$choice" ]]; then
        _cpro_load "$choice"
    fi
}

function cpro() {
    _cpro_check_jq || return 1

    local cmd="${1:-}"
    shift 2>/dev/null || true

    case "$cmd" in
        new-profile) _cpro_new_profile "$@" ;;
        load)        _cpro_load "$@" ;;
        list)        _cpro_list_names ;;
        show)        _cpro_show "$@" ;;
        edit)        _cpro_edit "$@" ;;
        help|-h)
            cat <<'EOF'
cpro — Copilot CLI profile manager

  Commands:
    cpro new-profile <name>       create a new profile in ~/.copilot/profiles
    cpro load [name]              load profile (no name = pick via fzf)
    cpro list                     list saved profiles (* = active)
    cpro show [name]              show profile contents (default: active)
    cpro edit <name>              open profile in $EDITOR
EOF
            ;;
        *)
            echo "Usage: cpro <new-profile|load|list|show|edit>" >&2
            return 1
            ;;
    esac
}
