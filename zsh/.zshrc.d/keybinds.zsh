# unbinds
bindkey -r "^G" # CTRL+G from send-break
stty susp undef  # free C-z for tmux prefix

bindkey '^b' ghostty_transparency_toggle_widget
