# --------------------------------------------------
# 60-keybindings.zsh
# Purpose:
#   Define custom key bindings
#
# Responsibilities:
#   - zle widgets
#   - bindkey mappings
# --------------------------------------------------

# unbinds
bindkey -r "^G" # CTRL+G from send-break 

# zle widgets
rg-fzf-widget() {
  LBUFFER=""
  RBUFFER=""
  zle reset-prompt
  rg-fzf
}
zle -N rg-fzf-widget
bindkey '^r' rg-fzf-widget
