# unbinds
bindkey -r "^G" # CTRL+G from send-break
stty susp undef  # free C-z for tmux prefix


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
