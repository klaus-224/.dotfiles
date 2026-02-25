# --------------------------------------------------
# codex-profile.zsh
# Purpose:
#   Minimal helpers around native Codex config/profiles.
#
# Usage:
#   xpro                  # interactive profile picker (fzf)
#   xpro profiles         # list profile names from config.toml
#   xpro profile          # show active profile from config.toml
#   xpro profile <name>   # set active profile in config.toml
#   xpro profile --clear  # remove top-level profile key
#   xpro edit             # open config.toml in $EDITOR
# --------------------------------------------------

_xpro_refresh_vars() {
    local script_dir repo_root
    script_dir="${${(%):-%x}:A:h}"
    repo_root="${script_dir}/../../.."
    _XPRO_CODEX_HOME="${CODEX_HOME:-${repo_root}/agents/.codex}"
    _XPRO_CONFIG="${CODEX_CONFIG_FILE:-$_XPRO_CODEX_HOME/config.toml}"
}

_xpro_ensure_paths() {
    mkdir -p "$_XPRO_CODEX_HOME"
}

_xpro_require_config() {
    if [[ ! -f "$_XPRO_CONFIG" ]]; then
        echo "Error: Codex config not found at $_XPRO_CONFIG" >&2
        return 1
    fi
}

_xpro_profiles() {
    _xpro_require_config || return 1
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
    ' "$_XPRO_CONFIG"
}

_xpro_profile_exists() {
    local wanted="$1"
    local current
    while IFS= read -r current; do
        [[ "$current" == "$wanted" ]] && return 0
    done < <(_xpro_profiles)
    return 1
}

_xpro_current_profile() {
    _xpro_require_config || return 1
    awk '
        BEGIN { in_top = 1 }
        /^[[:space:]]*\[/ { in_top = 0 }
        in_top && /^[[:space:]]*profile[[:space:]]*=/ {
            line = $0
            sub(/^[[:space:]]*profile[[:space:]]*=[[:space:]]*/, "", line)
            sub(/[[:space:]]*#.*/, "", line)
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", line)
            if (line ~ /^".*"$/ || line ~ /^'\''.*'\''$/) {
                line = substr(line, 2, length(line) - 2)
            }
            print line
            exit
        }
    ' "$_XPRO_CONFIG"
}

_xpro_write_profile() {
    local name="$1"
    if [[ -z "$name" ]]; then
        _xpro_clear_profile
        return
    fi
    local tmp
    tmp="$(mktemp)" || return 1

    awk -v profile="$name" '
        BEGIN { in_top = 1; replaced = 0; inserted = 0 }
        {
            if ($0 ~ /^[[:space:]]*\[/ && in_top == 1 && replaced == 0 && inserted == 0) {
                print "profile = \"" profile "\""
                inserted = 1
            }

            if (in_top == 1 && $0 ~ /^[[:space:]]*profile[[:space:]]*=/ && replaced == 0) {
                print "profile = \"" profile "\""
                replaced = 1
                next
            }

            if ($0 ~ /^[[:space:]]*\[/) in_top = 0
            print
        }
        END {
            if (replaced == 0 && inserted == 0) {
                print "profile = \"" profile "\""
            }
        }
    ' "$_XPRO_CONFIG" > "$tmp" || {
        rm -f "$tmp"
        return 1
    }

    cat "$tmp" > "$_XPRO_CONFIG" && rm -f "$tmp"
}

_xpro_clear_profile() {
    local tmp
    tmp="$(mktemp)" || return 1

    awk '
        BEGIN { in_top = 1; removed = 0 }
        {
            if ($0 ~ /^[[:space:]]*\[/) in_top = 0
            if (in_top == 1 && $0 ~ /^[[:space:]]*profile[[:space:]]*=/ && removed == 0) {
                removed = 1
                next
            }
            print
        }
    ' "$_XPRO_CONFIG" > "$tmp" || {
        rm -f "$tmp"
        return 1
    }

    cat "$tmp" > "$_XPRO_CONFIG" && rm -f "$tmp"
}

_xpro_cmd_profiles() {
    local active
    active="$(_xpro_current_profile)"

    local found=0
    local profile
    while IFS= read -r profile; do
        found=1
        if [[ "$profile" == "$active" ]]; then
            printf '* %s\n' "$profile"
        else
            printf '  %s\n' "$profile"
        fi
    done < <(_xpro_profiles)

    if [[ "$found" -eq 0 ]]; then
        echo "  (none)"
    fi
}

_xpro_cmd_profile() {
    local name="$1"
    if [[ -z "$name" ]]; then
        local active
        active="$(_xpro_current_profile)"
        if [[ -n "$active" ]]; then
            echo "$active"
        else
            echo "(none)"
        fi
        return 0
    fi

    if [[ "$name" == "--clear" ]]; then
        _xpro_clear_profile || return 1
        echo "Cleared top-level profile from $_XPRO_CONFIG"
        return 0
    fi

    if ! _xpro_profile_exists "$name"; then
        echo "Error: profile '$name' not found in $_XPRO_CONFIG" >&2
        return 1
    fi

    _xpro_write_profile "$name" || return 1
    echo "Active Codex profile set to: $name"
}

_xpro_cmd_pick() {
    local profiles=("${(@f)$(_xpro_profiles)}")
    if (( ${#profiles} == 0 )); then
        echo "No [profiles.*] entries found in $_XPRO_CONFIG" >&2
        return 1
    fi
    if ! command -v fzf >/dev/null 2>&1; then
        echo "fzf is required for interactive selection. Use: xpro profile <name>" >&2
        return 1
    fi

    local active
    active="$(_xpro_current_profile)"
    local choice
    choice="$(printf '%s\n' "${profiles[@]}" | \
        fzf --height=50% --layout=reverse --prompt='Codex profile> ' --header="Active: ${active:-"(none)"}")"

    [[ -n "$choice" ]] && _xpro_cmd_profile "$choice"
}

unalias xpro 2>/dev/null

function xpro {
    _xpro_refresh_vars
    local cmd="${1:-}"
    shift 2>/dev/null || true

    case "$cmd" in
        profiles|list|ls) _xpro_cmd_profiles ;;
        profile|use)       _xpro_cmd_profile "$@" ;;
        edit)              _xpro_ensure_paths; [[ -f "$_XPRO_CONFIG" ]] || : > "$_XPRO_CONFIG"; ${EDITOR:-nvim} "$_XPRO_CONFIG" ;;
        help|-h)
            cat <<'EOF'
xpro - Minimal Codex profile helper

  xpro                  fzf-pick and set top-level profile in config.toml
  xpro profiles         list [profiles.*] entries (* = active)
  xpro profile          show top-level profile value
  xpro profile <name>   set top-level profile value
  xpro profile --clear  remove top-level profile key
  xpro edit             open config.toml in $EDITOR
EOF
            ;;
        "")
            _xpro_cmd_pick
            ;;
        *)
            echo "Unknown command: $cmd (try 'xpro help')" >&2
            return 1
            ;;
    esac
}
