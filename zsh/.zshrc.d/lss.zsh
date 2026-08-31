lss() {
  local target
  target="$(fd --hidden --exclude .git --max-depth 1 | fzf)" || return
  nvim "$target"
}
