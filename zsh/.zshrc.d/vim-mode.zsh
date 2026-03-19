# -----------------------------
# Zsh vi-mode
# -----------------------------

# Enable vi keybindings
bindkey -v

# Tune key sequence timing
# Needed for multi-key bindings like 'jk'
export KEYTIMEOUT=20

# Map 'jk' in insert mode to normal mode
bindkey -M viins 'jk' vi-cmd-mode

# Backspace compatibility
bindkey '^?' backward-delete-char
bindkey '^H' backward-delete-char

# History search with arrow keys based on current buffer
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search

bindkey '^[[A' up-line-or-beginning-search
bindkey '^[[B' down-line-or-beginning-search

# Optional: Ctrl-p / Ctrl-n for history search too
bindkey '^P' up-line-or-beginning-search
bindkey '^N' down-line-or-beginning-search

# Useful insert-mode bindings
bindkey -M viins '^A' beginning-of-line
bindkey -M viins '^E' end-of-line
bindkey -M viins '^U' backward-kill-line
bindkey -M viins '^K' kill-line
bindkey -M viins '^W' backward-kill-word

# Cursor shape: block in normal mode, beam in insert mode
# 2 q = block
# 6 q = beam
function zle-keymap-select {
  if [[ $KEYMAP == vicmd ]]; then
    printf '\e[2 q'
  else
    printf '\e[6 q'
  fi
}

function zle-line-init {
  printf '\e[6 q'
}

zle -N zle-keymap-select
zle -N zle-line-init

# Reset cursor to insert-style before running commands
preexec() { printf '\e[6 q' }
