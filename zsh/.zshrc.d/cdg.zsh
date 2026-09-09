cdg() {
  local root
  root=$(git rev-parse --show-toplevel 2>/dev/null) || return
  cd "$root"
}
