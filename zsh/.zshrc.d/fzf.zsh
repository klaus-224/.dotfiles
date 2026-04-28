# --------------------------------------------------
# fzf.zsh
# Purpose:
#   fzf configuration, keybindings, and widgets.
# --------------------------------------------------

eval "$(fzf --zsh)"

# fzf-git
if [[ -s "$HOME/.dotfiles/scripts/fzf-git.sh" ]]; then
	source "$HOME/.dotfiles/scripts/fzf-git.sh"
fi

FD_DEFAULT_OPTIONS="--hidden --no-ignore --exclude .git --exclude node_modules"
EZA_OPTIONS="--icons --tree --color=always {}"
BAT_OPTIONS="--color=always -n --line-range :500 {}"

export FZF_DEFAULT_OPTS="--style minimal"

# file picker
export FZF_CTRL_T_OPTS="--prompt 'Files> ' \
  --preview 'bat $BAT_OPTIONS'"

fzf-cd-widget() {
  local dir

  dir=$(
    fd --type d $FD_DEFAULT_OPTIONS |
    fzf \
      --prompt "Directories> " \
      --preview "eza $EZA_OPTIONS | head -200"
  )

  [[ -z "$dir" ]] && return
  cd "$dir" || return
}
zle -N fzf-cd-widget
bindkey '^G' fzf-cd-widget
