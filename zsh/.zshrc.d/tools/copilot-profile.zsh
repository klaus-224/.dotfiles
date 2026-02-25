# --------------------------------------------------
# copilot-profile.zsh
# Purpose:
#   Manage named profiles for GitHub Copilot CLI.
#   Switch tools, MCP servers, skills, permissions,
#   and model settings with a single command.
#
# Usage:
#   cpro                       # fzf-pick a profile to load
#   cpro save <name>           # snapshot current config as a profile
#   cpro load <name>           # load a saved profile
#   cpro list                  # list saved profiles
#   cpro show [name]           # show profile contents (default: active)
#   cpro delete <name>         # delete a profile
#   cpro edit <name>           # open profile in $EDITOR
#   cpro diff <a> [b]          # diff two profiles (b defaults to active)
#
#   cpro model [name]          # get/set model
#   cpro reasoning [off|low|medium|high]
#   cpro mcp <on|off> <server> # toggle an MCP server
#   cpro skill <add|rm> <dir>  # add/remove a skill directory
#   cpro trust <add|rm> <dir>  # add/remove a trusted folder
# --------------------------------------------------

_CPRO_DIR="${COPILOT_PROFILES_DIR:-$HOME/.copilot/profiles}"
_CPRO_CONFIG="$HOME/.copilot/config.json"
_CPRO_MCP="$HOME/.copilot/mcp-config.json"

# ── helpers ──────────────────────────────────────

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

# ── save / load ──────────────────────────────────

_cpro_save() {
  local name="$1"
  if [[ -z "$name" ]]; then
    echo "Usage: cpro save <name>" >&2
    return 1
  fi
  _cpro_ensure_dir
  local dest="$(_cpro_profile_path "$name")"
  mkdir -p "$dest"
  cp "$_CPRO_CONFIG" "$dest/config.json"
  cp "$_CPRO_MCP" "$dest/mcp-config.json"
  echo "Profile '$name' saved."
}

_cpro_load() {
  local name="$1"
  if [[ -z "$name" ]]; then
    echo "Usage: cpro load <name>" >&2
    return 1
  fi
  local src="$(_cpro_profile_path "$name")"
  if [[ ! -d "$src" ]]; then
    echo "Error: profile '$name' not found." >&2
    return 1
  fi
  cp "$src/config.json" "$_CPRO_CONFIG"
  cp "$src/mcp-config.json" "$_CPRO_MCP"
  echo "$name" > "$_CPRO_DIR/.active"
  echo "Profile '$name' loaded."
}

_cpro_delete() {
  local name="$1"
  if [[ -z "$name" ]]; then
    echo "Usage: cpro delete <name>" >&2
    return 1
  fi
  local src="$(_cpro_profile_path "$name")"
  if [[ ! -d "$src" ]]; then
    echo "Error: profile '$name' not found." >&2
    return 1
  fi
  rm -rf "$src"
  if [[ "$(_cpro_active_name)" == "$name" ]]; then
    rm -f "$_CPRO_DIR/.active"
  fi
  echo "Profile '$name' deleted."
}

# ── show / diff ──────────────────────────────────

_cpro_show() {
  local name="${1:-$(_cpro_active_name)}"
  if [[ "$name" == "(none)" ]]; then
    echo "── active config (no profile loaded) ──"
    echo "config.json:"
    jq '.' "$_CPRO_CONFIG"
    echo "\nmcp-config.json:"
    jq '.' "$_CPRO_MCP"
    return
  fi
  local src="$(_cpro_profile_path "$name")"
  if [[ ! -d "$src" ]]; then
    echo "── active config (no profile loaded) ──"
    echo "config.json:"
    jq '.' "$_CPRO_CONFIG"
    echo "\nmcp-config.json:"
    jq '.' "$_CPRO_MCP"
    return
  fi
  echo "── profile: $name ──"
  echo "config.json:"
  jq '.' "$src/config.json"
  echo "\nmcp-config.json:"
  jq '.' "$src/mcp-config.json"
}

_cpro_diff() {
  local a="$1" b="$2"
  if [[ -z "$a" ]]; then
    echo "Usage: cpro diff <profile_a> [profile_b]" >&2
    return 1
  fi
  local path_a="$(_cpro_profile_path "$a")"
  if [[ ! -d "$path_a" ]]; then
    echo "Error: profile '$a' not found." >&2
    return 1
  fi
  if [[ -n "$b" ]]; then
    local path_b="$(_cpro_profile_path "$b")"
    if [[ ! -d "$path_b" ]]; then
      echo "Error: profile '$b' not found." >&2
      return 1
    fi
    echo "── config.json: $a vs $b ──"
    diff --color=always <(jq --sort-keys '.' "$path_a/config.json") <(jq --sort-keys '.' "$path_b/config.json") || true
    echo "\n── mcp-config.json: $a vs $b ──"
    diff --color=always <(jq --sort-keys '.' "$path_a/mcp-config.json") <(jq --sort-keys '.' "$path_b/mcp-config.json") || true
  else
    echo "── config.json: $a vs active ──"
    diff --color=always <(jq --sort-keys '.' "$path_a/config.json") <(jq --sort-keys '.' "$_CPRO_CONFIG") || true
    echo "\n── mcp-config.json: $a vs active ──"
    diff --color=always <(jq --sort-keys '.' "$path_a/mcp-config.json") <(jq --sort-keys '.' "$_CPRO_MCP") || true
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
  ${EDITOR:-nvim} "$src/config.json" "$src/mcp-config.json"
}

# ── toggles: model ───────────────────────────────

_cpro_model() {
  if [[ -z "$1" ]]; then
    jq -r '.model // "not set"' "$_CPRO_CONFIG"
    return
  fi
  local tmp
  tmp=$(jq --arg m "$1" '.model = $m' "$_CPRO_CONFIG") && echo "$tmp" > "$_CPRO_CONFIG"
  echo "Model set to: $1"
}

# ── toggles: reasoning ───────────────────────────

_cpro_reasoning() {
  if [[ -z "$1" ]]; then
    local effort show
    effort=$(jq -r '.reasoning_effort // "not set"' "$_CPRO_CONFIG")
    show=$(jq -r '.show_reasoning // "not set"' "$_CPRO_CONFIG")
    echo "reasoning_effort: $effort"
    echo "show_reasoning: $show"
    return
  fi
  if [[ "$1" == "off" ]]; then
    local tmp
    tmp=$(jq '.show_reasoning = false' "$_CPRO_CONFIG") && echo "$tmp" > "$_CPRO_CONFIG"
    echo "Reasoning display disabled."
  else
    local tmp
    tmp=$(jq --arg e "$1" '.reasoning_effort = $e | .show_reasoning = true' "$_CPRO_CONFIG") && echo "$tmp" > "$_CPRO_CONFIG"
    echo "Reasoning set to: $1 (display enabled)"
  fi
}

# ── toggles: MCP servers ─────────────────────────

_cpro_mcp() {
  local action="$1" server="$2"
  if [[ -z "$action" ]]; then
    echo "Configured MCP servers:"
    jq -r '.mcpServers | keys[]' "$_CPRO_MCP" 2>/dev/null || echo "  (none)"
    return
  fi
  if [[ -z "$server" ]]; then
    echo "Usage: cpro mcp <on|off> <server>" >&2
    return 1
  fi
  case "$action" in
    on)
      local disabled="$_CPRO_DIR/.disabled-mcp"
      if [[ -f "$disabled/$server.json" ]]; then
        local entry
        entry=$(cat "$disabled/$server.json")
        local tmp
        tmp=$(jq --arg s "$server" --argjson e "$entry" '.mcpServers[$s] = $e' "$_CPRO_MCP") && echo "$tmp" > "$_CPRO_MCP"
        rm "$disabled/$server.json"
        echo "MCP server '$server' enabled."
      else
        echo "No disabled config found for '$server'." >&2
        return 1
      fi
      ;;
    off)
      local entry
      entry=$(jq --arg s "$server" '.mcpServers[$s]' "$_CPRO_MCP")
      if [[ "$entry" == "null" ]]; then
        echo "MCP server '$server' not found." >&2
        return 1
      fi
      mkdir -p "$_CPRO_DIR/.disabled-mcp"
      echo "$entry" > "$_CPRO_DIR/.disabled-mcp/$server.json"
      local tmp
      tmp=$(jq --arg s "$server" 'del(.mcpServers[$s])' "$_CPRO_MCP") && echo "$tmp" > "$_CPRO_MCP"
      echo "MCP server '$server' disabled (config preserved)."
      ;;
    *)
      echo "Usage: cpro mcp <on|off> <server>" >&2
      return 1
      ;;
  esac
}

# ── toggles: skills ──────────────────────────────

_cpro_skill() {
  local action="$1" dir="$2"
  if [[ -z "$action" ]]; then
    echo "Skill directories:"
    jq -r '.skill_directories // [] | .[]' "$_CPRO_CONFIG" 2>/dev/null || echo "  (none)"
    return
  fi
  if [[ -z "$dir" ]]; then
    echo "Usage: cpro skill <add|rm> <directory>" >&2
    return 1
  fi
  dir="${dir:A}"  # resolve to absolute path
  case "$action" in
    add)
      local tmp
      tmp=$(jq --arg d "$dir" '.skill_directories = ((.skill_directories // []) + [$d] | unique)' "$_CPRO_CONFIG") && echo "$tmp" > "$_CPRO_CONFIG"
      echo "Skill directory added: $dir"
      ;;
    rm)
      local tmp
      tmp=$(jq --arg d "$dir" '.skill_directories = [(.skill_directories // [])[] | select(. != $d)]' "$_CPRO_CONFIG") && echo "$tmp" > "$_CPRO_CONFIG"
      echo "Skill directory removed: $dir"
      ;;
    *)
      echo "Usage: cpro skill <add|rm> <directory>" >&2
      return 1
      ;;
  esac
}

# ── toggles: trusted folders ─────────────────────

_cpro_trust() {
  local action="$1" dir="$2"
  if [[ -z "$action" ]]; then
    echo "Trusted folders:"
    jq -r '.trusted_folders // [] | .[]' "$_CPRO_CONFIG" 2>/dev/null || echo "  (none)"
    return
  fi
  if [[ -z "$dir" ]]; then
    echo "Usage: cpro trust <add|rm> <directory>" >&2
    return 1
  fi
  dir="${dir:A}"  # resolve to absolute path
  case "$action" in
    add)
      local tmp
      tmp=$(jq --arg d "$dir" '.trusted_folders = ((.trusted_folders // []) + [$d] | unique)' "$_CPRO_CONFIG") && echo "$tmp" > "$_CPRO_CONFIG"
      echo "Trusted folder added: $dir"
      ;;
    rm)
      local tmp
      tmp=$(jq --arg d "$dir" '.trusted_folders = [(.trusted_folders // [])[] | select(. != $d)]' "$_CPRO_CONFIG") && echo "$tmp" > "$_CPRO_CONFIG"
      echo "Trusted folder removed: $dir"
      ;;
    *)
      echo "Usage: cpro trust <add|rm> <directory>" >&2
      return 1
      ;;
  esac
}

# ── fzf picker ───────────────────────────────────

_cpro_pick() {
  _cpro_ensure_dir
  local profiles=()
  for dir in "$_CPRO_DIR"/*(N/); do
    profiles+=("${dir:t}")
  done
  if (( ${#profiles} == 0 )); then
    echo "No saved profiles. Use 'cpro save <name>' to create one." >&2
    return 1
  fi
  if ! command -v fzf >/dev/null 2>&1; then
    echo "fzf is required for interactive selection. Use 'cpro load <name>' instead." >&2
    return 1
  fi
  local active
  active="$(_cpro_active_name)"
  local choice
  choice=$(printf '%s\n' "${profiles[@]}" | \
    fzf --height=50% --layout=reverse \
        --prompt='Copilot Profile> ' \
        --header="Active: $active" \
        --preview="echo '── config.json ──' && jq -C '.' '$_CPRO_DIR/{}/config.json' 2>/dev/null && echo '' && echo '── mcp-config.json ──' && jq -C '.' '$_CPRO_DIR/{}/mcp-config.json' 2>/dev/null")
  if [[ -n "$choice" ]]; then
    _cpro_load "$choice"
  fi
}

# ── main entry point ─────────────────────────────

cpro() {
  _cpro_check_jq || return 1

  local cmd="${1:-}"
  shift 2>/dev/null || true

  case "$cmd" in
    save)      _cpro_save "$@" ;;
    load)      _cpro_load "$@" ;;
    list|ls)   _cpro_list_names ;;
    show)      _cpro_show "$@" ;;
    delete|rm) _cpro_delete "$@" ;;
    edit)      _cpro_edit "$@" ;;
    diff)      _cpro_diff "$@" ;;
    model)     _cpro_model "$@" ;;
    reasoning) _cpro_reasoning "$@" ;;
    mcp)       _cpro_mcp "$@" ;;
    skill)     _cpro_skill "$@" ;;
    trust)     _cpro_trust "$@" ;;
    help|-h|--help)
      cat <<'EOF'
cpro — Copilot CLI profile manager

  Profiles:
    cpro                          fzf-pick a profile to load
    cpro save <name>              snapshot current config as a profile
    cpro load <name>              load a saved profile
    cpro list                     list saved profiles (* = active)
    cpro show [name]              show profile contents (default: active)
    cpro delete <name>            delete a profile
    cpro edit <name>              open profile in $EDITOR
    cpro diff <a> [b]             diff two profiles (b defaults to active)

  Toggles (modify active config directly):
    cpro model [name]             get/set model
    cpro reasoning [off|low|medium|high]
    cpro mcp                      list MCP servers
    cpro mcp <on|off> <server>    enable/disable an MCP server
    cpro skill                    list skill directories
    cpro skill <add|rm> <dir>     add/remove a skill directory
    cpro trust                    list trusted folders
    cpro trust <add|rm> <dir>     add/remove a trusted folder
EOF
      ;;
    "")        _cpro_pick ;;
    *)
      echo "Unknown command: $cmd (try 'cpro help')" >&2
      return 1
      ;;
  esac
}
