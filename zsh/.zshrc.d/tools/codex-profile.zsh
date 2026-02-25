# --------------------------------------------------
# codex-profile.zsh
# Purpose:
#   Manage named profiles for Codex CLI.
#   Use native `codex --profile` switching, plus optional config snapshots.
#
# Function mnemonic: [COD]ex [PRO]file
#
# Usage:
#   codpro                       # fzf-pick active native Codex profile
#   codpro profiles              # list native profiles from config.toml
#   codpro profile [name]        # get/set active native profile
#   codpro run [args...]         # run `codex --profile <active> ...`
#
#   codpro save <name>           # snapshot current config as a profile
#   codpro load <name>           # load a saved snapshot
#   codpro list                  # list saved snapshots
#   codpro show [name]           # show snapshot contents (default: active)
#   codpro delete <name>         # delete a snapshot
#   codpro edit <name>           # open snapshot in $EDITOR
#   codpro diff <a> [b]          # diff two snapshots (b defaults to active)
#
# Environment variables:
#   CODEX_PROFILES_DIR           # where profiles are saved
#   CODEX_CONFIG_FILE            # config file to snapshot/load
# --------------------------------------------------

_CODPRO_DIR="${CODEX_PROFILES_DIR:-$HOME/.dotfiles/agents/.codex/profiles}"
_CODPRO_CONFIG="${CODEX_CONFIG_FILE:-$HOME/.codex/config.toml}"
_CODPRO_ACTIVE_SNAPSHOT_FILE="$_CODPRO_DIR/.active"
_CODPRO_ACTIVE_PROFILE_FILE="$_CODPRO_DIR/.active-profile"

# -- helpers --------------------------------------------------------------

_codpro_ensure_dir() { [[ -d "$_CODPRO_DIR" ]] || mkdir -p "$_CODPRO_DIR"; }

_codpro_active_name() {
    if [[ -f "$_CODPRO_ACTIVE_SNAPSHOT_FILE" ]]; then
        cat "$_CODPRO_ACTIVE_SNAPSHOT_FILE"
    else
        echo "(none)"
    fi
}

_codpro_active_profile_name() {
    if [[ -f "$_CODPRO_ACTIVE_PROFILE_FILE" ]]; then
        cat "$_CODPRO_ACTIVE_PROFILE_FILE"
    else
        echo "(none)"
    fi
}

_codpro_profile_path() { printf '%s/%s' "$_CODPRO_DIR" "$1"; }

_codpro_codex_profiles() {
    [[ -f "$_CODPRO_CONFIG" ]] || return 0
    awk '
        /^\[profiles\./ {
            line = $0
            sub(/^\[profiles\./, "", line)
            sub(/\]$/, "", line)
            if (substr(line, 1, 1) == "\"") {
                line = substr(line, 2)
                end = index(line, "\"")
                if (end <= 0) next
                name = substr(line, 1, end - 1)
            } else {
                split(line, parts, /\./)
                name = parts[1]
            }
            if (name != "" && !seen[name]++) print name
        }
    ' "$_CODPRO_CONFIG"
}

_codpro_profile_exists() {
    local wanted="$1"
    local current
    while IFS= read -r current; do
        [[ "$current" == "$wanted" ]] && return 0
    done < <(_codpro_codex_profiles)
    return 1
}

_codpro_print_toml() {
    local file="$1"
    if command -v bat >/dev/null 2>&1; then
        bat --style=plain --paging=never "$file"
    else
        cat "$file"
    fi
}

_codpro_show_active_config() {
    if [[ ! -f "$_CODPRO_CONFIG" ]]; then
        echo "Error: Codex config not found at $_CODPRO_CONFIG" >&2
        return 1
    fi
    echo "-- active config (no profile loaded) --"
    _codpro_print_toml "$_CODPRO_CONFIG"
}

_codpro_list_names() {
    _codpro_ensure_dir
    local active
    active="$(_codpro_active_name)"
    for dir in "$_CODPRO_DIR"/*(N/); do
        local name="${dir:t}"
        if [[ "$name" == "$active" ]]; then
            printf '* %s\n' "$name"
        else
            printf '  %s\n' "$name"
        fi
    done
}

_codpro_list_profiles() {
    local active
    active="$(_codpro_active_profile_name)"
    local found=0
    local profile
    while IFS= read -r profile; do
        found=1
        if [[ "$profile" == "$active" ]]; then
            printf '* %s\n' "$profile"
        else
            printf '  %s\n' "$profile"
        fi
    done < <(_codpro_codex_profiles)

    if [[ "$found" -eq 0 ]]; then
        echo "  (none)"
    fi
}

# -- save / load ----------------------------------------------------------

function _codpro_save() {
    local name="$1"
    if [[ -z "$name" ]]; then
        echo "Usage: codpro save <name>" >&2
        return 1
    fi
    if [[ ! -f "$_CODPRO_CONFIG" ]]; then
        echo "Error: Codex config not found at $_CODPRO_CONFIG" >&2
        return 1
    fi
    _codpro_ensure_dir
    local dest="$(_codpro_profile_path "$name")"
    mkdir -p "$dest"
    cp "$_CODPRO_CONFIG" "$dest/config.toml"
    echo "Profile '$name' saved."
}

function _codpro_load() {
    local name="$1"
    if [[ -z "$name" ]]; then
        echo "Usage: codpro load <name>" >&2
        return 1
    fi
    local src="$(_codpro_profile_path "$name")"
    if [[ ! -d "$src" ]]; then
        echo "Error: profile '$name' not found." >&2
        return 1
    fi
    if [[ ! -f "$src/config.toml" ]]; then
        echo "Error: profile '$name' is missing config.toml." >&2
        return 1
    fi
    mkdir -p "${_CODPRO_CONFIG:h}"
    cp "$src/config.toml" "$_CODPRO_CONFIG"
    echo "$name" > "$_CODPRO_ACTIVE_SNAPSHOT_FILE"
    echo "Profile '$name' loaded."
}

function _codpro_delete() {
    local name="$1"
    if [[ -z "$name" ]]; then
        echo "Usage: codpro delete <name>" >&2
        return 1
    fi
    local src="$(_codpro_profile_path "$name")"
    if [[ ! -d "$src" ]]; then
        echo "Error: profile '$name' not found." >&2
        return 1
    fi
    rm -rf "$src"
    if [[ "$(_codpro_active_name)" == "$name" ]]; then
        rm -f "$_CODPRO_ACTIVE_SNAPSHOT_FILE"
    fi
    echo "Profile '$name' deleted."
}

# -- show / diff ----------------------------------------------------------

function _codpro_show() {
    local name="${1:-$(_codpro_active_name)}"
    if [[ "$name" == "(none)" ]]; then
        _codpro_show_active_config
        return
    fi
    local src="$(_codpro_profile_path "$name")"
    if [[ ! -d "$src" ]]; then
        _codpro_show_active_config
        return
    fi
    if [[ ! -f "$src/config.toml" ]]; then
        echo "Error: profile '$name' is missing config.toml." >&2
        return 1
    fi
    echo "-- profile: $name --"
    _codpro_print_toml "$src/config.toml"
}

function _codpro_diff() {
    local a="$1" b="$2"
    if [[ -z "$a" ]]; then
        echo "Usage: codpro diff <profile_a> [profile_b]" >&2
        return 1
    fi
    local path_a="$(_codpro_profile_path "$a")"
    if [[ ! -f "$path_a/config.toml" ]]; then
        echo "Error: profile '$a' not found." >&2
        return 1
    fi

    if [[ -n "$b" ]]; then
        local path_b="$(_codpro_profile_path "$b")"
        if [[ ! -f "$path_b/config.toml" ]]; then
            echo "Error: profile '$b' not found." >&2
            return 1
        fi
        echo "-- config.toml: $a vs $b --"
        diff --color=always "$path_a/config.toml" "$path_b/config.toml" || true
    else
        if [[ ! -f "$_CODPRO_CONFIG" ]]; then
            echo "Error: Codex config not found at $_CODPRO_CONFIG" >&2
            return 1
        fi
        echo "-- config.toml: $a vs active --"
        diff --color=always "$path_a/config.toml" "$_CODPRO_CONFIG" || true
    fi
}

function _codpro_edit() {
    local name="$1"
    if [[ -z "$name" ]]; then
        echo "Usage: codpro edit <name>" >&2
        return 1
    fi
    local src="$(_codpro_profile_path "$name")"
    if [[ ! -f "$src/config.toml" ]]; then
        echo "Error: profile '$name' not found." >&2
        return 1
    fi
    ${EDITOR:-nvim} "$src/config.toml"
}

# -- native profile switching --------------------------------------------

function _codpro_profile() {
    local name="$1"
    if [[ -z "$name" ]]; then
        echo "$(_codpro_active_profile_name)"
        return
    fi
    if ! _codpro_profile_exists "$name"; then
        echo "Error: Codex profile '$name' not found in $_CODPRO_CONFIG" >&2
        return 1
    fi
    _codpro_ensure_dir
    echo "$name" > "$_CODPRO_ACTIVE_PROFILE_FILE"
    echo "Active Codex profile set to: $name"
}

function _codpro_run() {
    local arg
    for arg in "$@"; do
        if [[ "$arg" == "--profile" || "$arg" == "-p" ]]; then
            command codex "$@"
            return
        fi
    done

    local active
    active="$(_codpro_active_profile_name)"
    if [[ "$active" == "(none)" ]]; then
        command codex "$@"
        return
    fi

    command codex --profile "$active" "$@"
}

# -- fzf pickers ----------------------------------------------------------

function _codpro_pick_snapshot() {
    _codpro_ensure_dir
    local profiles=()
    for dir in "$_CODPRO_DIR"/*(N/); do
        profiles+=("${dir:t}")
    done
    if (( ${#profiles} == 0 )); then
        echo "No saved profiles. Use 'codpro save <name>' to create one." >&2
        return 1
    fi
    if ! command -v fzf >/dev/null 2>&1; then
        echo "fzf is required for interactive selection. Use 'codpro load <name>' instead." >&2
        return 1
    fi
    local active
    active="$(_codpro_active_name)"
    local choice
    choice=$(printf '%s\n' "${profiles[@]}" | \
        fzf --height=50% --layout=reverse \
        --prompt='Codex Profile> ' \
        --header="Active: $active" \
        --preview="cat '$_CODPRO_DIR/{}/config.toml' 2>/dev/null")
    if [[ -n "$choice" ]]; then
        _codpro_load "$choice"
    fi
}

function _codpro_pick_profile() {
    local profiles=("${(@f)$(_codpro_codex_profiles)}")
    if (( ${#profiles} == 0 )); then
        echo "No native Codex profiles found in $_CODPRO_CONFIG" >&2
        return 1
    fi
    if ! command -v fzf >/dev/null 2>&1; then
        echo "fzf is required for interactive selection. Use 'codpro profile <name>' instead." >&2
        return 1
    fi

    local active
    active="$(_codpro_active_profile_name)"
    local choice
    choice=$(printf '%s\n' "${profiles[@]}" | \
        fzf --height=50% --layout=reverse \
        --prompt='Codex --profile> ' \
        --header="Active: $active")
    if [[ -n "$choice" ]]; then
        _codpro_profile "$choice"
    fi
}

# -- main entry point -----------------------------------------------------

function codpro() {
    local cmd="${1:-}"
    shift 2>/dev/null || true

    case "$cmd" in
        profiles)  _codpro_list_profiles ;;
        profile|use) _codpro_profile "$@" ;;
        run|exec)  _codpro_run "$@" ;;
        pick-snapshot) _codpro_pick_snapshot ;;
        save)      _codpro_save "$@" ;;
        load)      _codpro_load "$@" ;;
        list|ls)   _codpro_list_names ;;
        show)      _codpro_show "$@" ;;
        delete|rm) _codpro_delete "$@" ;;
        edit)      _codpro_edit "$@" ;;
        diff)      _codpro_diff "$@" ;;
        help|-h)
            cat <<'EOF'
codpro - Codex CLI profile manager

  Native Codex profiles (--profile):
    codpro                         fzf-pick active native profile
    codpro profiles                list native profiles in ~/.codex/config.toml
    codpro profile [name]          get/set active native profile
    codpro run [args...]           run codex --profile <active> [args...]

  Snapshot profiles:
    codpro save <name>             snapshot current config as a profile
    codpro load <name>             load a saved snapshot
    codpro list                    list saved snapshots (* = active snapshot)
    codpro show [name]             show snapshot contents (default: active snapshot)
    codpro delete <name>           delete a snapshot
    codpro edit <name>             open snapshot in $EDITOR
    codpro diff <a> [b]            diff two snapshots (b defaults to active config)

  Env variables:
    CODEX_PROFILES_DIR             where profiles are saved
    CODEX_CONFIG_FILE              Codex config file to manage
EOF
            ;;
        "")
            if ! _codpro_pick_profile; then
                _codpro_pick_snapshot
            fi
            ;;
        *)
            echo "Unknown command: $cmd (try 'codpro help')" >&2
            return 1
            ;;
    esac
}

# short alias
alias xpro='codpro'
