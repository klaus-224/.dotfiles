# --------------------------------------------------
# 50-keybinds.zsh
# Purpose:
# 	- register tool as zle widget
# 	- assign a keybind
#
# Responsibilities:
#   - zle widgets
#   - bindkey mappings
# --------------------------------------------------

# unbinds
bindkey -r "^G" # CTRL+G from send-break 

# zle widgets
# rg-fzf-widget() {
#   LBUFFER=""
#   RBUFFER=""
#   zle reset-prompt
#   rg-fzf
# }
# zle -N rg-fzf-widget
# bindkey '^r' rg-fzf-widget

# Toggle Ghostty transparency with Ctrl-T
ghostty_transparency_toggle_widget() {
  if (( $+functions[ghostty-transparency] )); then
    ghostty-transparency toggle
  else
    zle -M "ghostty-transparency not loaded"
  fi
  zle reset-prompt
}
zle -N ghostty_transparency_toggle_widget
bindkey '^b' ghostty_transparency_toggle_widget
