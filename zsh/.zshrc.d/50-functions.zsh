# --------------------------------------------------
# 50-functions.zsh
# Purpose:
#   Define reusable shell functions.
#
# Responsibilities:
#   - Multi-step commands
#   - Commands that take arguments
#   - Safer replacements for complex aliases
#
# Rules:
#   - Functions only
#   - No aliases
#   - No tool initialization
# --------------------------------------------------

# Git branch switcher with fzf
fbr() {
  local branches branch
  branches=$(git branch -a) &&
  branch=$(echo "$branches" | fzf +m) &&
  git checkout $(echo "$branch" | sed "s/.* //" | sed "s#remotes/[^/]*/##")
}

# Zle widget for keybinding
fzf-git-branch-widget() {
  fbr
  zle reset-prompt
}
zle -N fzf-git-branch-widget
bindkey '^b' fzf-git-branch-widget  # Ctrl+B
