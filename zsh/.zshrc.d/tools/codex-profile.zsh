# DISABLED FOR NOW
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

# _xpro_refresh_vars() {
#     local script_dir repo_root
#     script_dir="${${(%):-%x}:A:h}"
#     repo_root="${script_dir}/../../.."
#     _XPRO_CODEX_HOME="${CODEX_HOME:-${repo_root}/agents/.codex}"
#     _XPRO_CONFIG="${CODEX_CONFIG_FILE:-$_XPRO_CODEX_HOME/config.toml}"
# }
#
# _xpro_ensure_paths() {
#     mkdir -p "$_XPRO_CODEX_HOME"
# }
#
# _xpro_require_config() {
#     if [[ ! -f "$_XPRO_CONFIG" ]]; then
#         echo "Error: Codex config not found at $_XPRO_CONFIG" >&2
#         return 1
#     fi
# }
#
# _xpro_require_tools() {
#     local missing=0
#     if ! command -v toml >/dev/null 2>&1; then
#         echo "Error: toml-cli is required. Install with cargo: cargo install toml-cli" >&2
#         missing=1
#     fi
#     if ! command -v jq >/dev/null 2>&1; then
#         echo "Error: jq is required. Install with brew: brew install jq" >&2
#         missing=1
#     fi
#     (( missing == 0 ))
# }
#
# _xpro_profiles() {
#     _xpro_require_config || return 1
#     _xpro_require_tools || return 1
#
#     local profiles_json
#     profiles_json="$(toml get --format=json "$_XPRO_CONFIG" profiles 2>/dev/null || true)"
#     [[ -z "$profiles_json" ]] && return 0
#
#     printf '%s\n' "$profiles_json" | jq -r '
#         if type == "object" then
#             keys_unsorted[]
#         else
#             empty
#         end
#     '
# }
#
# _xpro_profile_exists() {
#     local wanted="$1"
#     local current
#     while IFS= read -r current; do
#         [[ "$current" == "$wanted" ]] && return 0
#     done < <(_xpro_profiles)
#     return 1
# }
#
# _xpro_current_profile() {
#     _xpro_require_config || return 1
#     _xpro_require_tools || return 1
#
#     toml get -r "$_XPRO_CONFIG" profile 2>/dev/null || true
# }
#
# _xpro_write_profile() {
#     local name="$1"
#     if [[ -z "$name" ]]; then
#         _xpro_clear_profile
#         return
#     fi
#     _xpro_require_config || return 1
#     _xpro_require_tools || return 1
#
#     local tmp
#     tmp="$(mktemp)" || return 1
#
#     toml set "$_XPRO_CONFIG" profile "$name" > "$tmp" || {
#         rm -f "$tmp"
#         return 1
#     }
#
#     cat "$tmp" > "$_XPRO_CONFIG" && rm -f "$tmp"
# }
#
# _xpro_clear_profile() {
#     _xpro_require_config || return 1
#     local tmp
#     local line
#     local in_top=1
#     local removed=0
#     tmp="$(mktemp)" || return 1
#
#     while IFS= read -r line || [[ -n "$line" ]]; do
#         if [[ "$line" =~ ^[[:space:]]*\[ ]]; then
#             in_top=0
#         fi
#
#         if (( in_top == 1 && removed == 0 )) && [[ "$line" =~ ^[[:space:]]*profile[[:space:]]*= ]]; then
#             removed=1
#             continue
#         fi
#
#         printf '%s\n' "$line" >> "$tmp"
#     done < "$_XPRO_CONFIG"
#
#     cat "$tmp" > "$_XPRO_CONFIG" && rm -f "$tmp"
# }
#
# _xpro_cmd_profiles() {
#     local active
#     active="$(_xpro_current_profile)" || return 1
#
#     local profiles_raw
#     profiles_raw="$(_xpro_profiles)" || return 1
#     local profiles=("${(@f)profiles_raw}")
#
#     local found=0
#     local profile
#     for profile in "${profiles[@]}"; do
#         found=1
#         if [[ "$profile" == "$active" ]]; then
#             printf '* %s\n' "$profile"
#         else
#             printf '  %s\n' "$profile"
#         fi
#     done
#
#     if [[ "$found" -eq 0 ]]; then
#         echo "  (none)"
#     fi
# }
#
# _xpro_cmd_profile() {
#     local name="$1"
#     if [[ -z "$name" ]]; then
#         local active
#         active="$(_xpro_current_profile)" || return 1
#         if [[ -n "$active" ]]; then
#             echo "$active"
#         else
#             echo "(none)"
#         fi
#         return 0
#     fi
#
#     if [[ "$name" == "--clear" ]]; then
#         _xpro_clear_profile || return 1
#         echo "Cleared top-level profile from $_XPRO_CONFIG"
#         return 0
#     fi
#
#     if ! _xpro_profile_exists "$name"; then
#         echo "Error: profile '$name' not found in $_XPRO_CONFIG" >&2
#         return 1
#     fi
#
#     _xpro_write_profile "$name" || return 1
#     echo "Active Codex profile set to: $name"
# }
#
# _xpro_cmd_pick() {
#     local profiles_raw
#     profiles_raw="$(_xpro_profiles)" || return 1
#     local profiles=("${(@f)profiles_raw}")
#     if (( ${#profiles} == 0 )); then
#         echo "No [profiles.*] entries found in $_XPRO_CONFIG" >&2
#         return 1
#     fi
#     if ! command -v fzf >/dev/null 2>&1; then
#         echo "fzf is required for interactive selection. Use: xpro profile <name>" >&2
#         return 1
#     fi
#
#     local active
#     active="$(_xpro_current_profile)" || return 1
#     local choice
#     choice="$(printf '%s\n' "${profiles[@]}" | \
#         fzf --height=50% --layout=reverse --prompt='Codex profile> ' --header="Active: ${active:-"(none)"}")"
#
#     [[ -n "$choice" ]] && _xpro_cmd_profile "$choice"
# }
#
# unalias xpro 2>/dev/null
#
# function xpro {
#     _xpro_refresh_vars
#     local cmd="${1:-}"
#     shift 2>/dev/null || true
#
#     case "$cmd" in
#         profiles|list|ls) _xpro_cmd_profiles ;;
#         profile|use)       _xpro_cmd_profile "$@" ;;
#         edit)              _xpro_ensure_paths; [[ -f "$_XPRO_CONFIG" ]] || : > "$_XPRO_CONFIG"; ${EDITOR:-nvim} "$_XPRO_CONFIG" ;;
#         help|-h)
#             cat <<'EOF'
# xpro - Minimal Codex profile helper
#
#   xpro                  fzf-pick and set top-level profile in config.toml
#   xpro profiles         list [profiles.*] entries (* = active)
#   xpro profile          show top-level profile value
#   xpro profile <name>   set top-level profile value
#   xpro profile --clear  remove top-level profile key
#   xpro edit             open config.toml in $EDITOR
# EOF
#             ;;
#         "")
#             _xpro_cmd_pick
#             ;;
#         *)
#             echo "Unknown command: $cmd (try 'xpro help')" >&2
#             return 1
#             ;;
#     esac
# }
