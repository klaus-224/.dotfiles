# unbinds
bindkey -r "^G" # CTRL+G from send-break
[[ -t 0 ]] && stty susp undef  # free C-z for tmux prefix, only with a terminal

# Optional local widget; do not bind a name that cannot be invoked.
if (( $+functions[ghostty_transparency_toggle_widget] )); then
  zle -N ghostty_transparency_toggle_widget
fi
if zle -l ghostty_transparency_toggle_widget; then
  bindkey '^b' ghostty_transparency_toggle_widget
fi
