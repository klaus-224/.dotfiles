eval "$(fzf --zsh)"

# fzf-git
if [[ -s "$HOME/.dotfiles/scripts/fzf-git.sh" ]]; then
	source "$HOME/.dotfiles/scripts/fzf-git.sh"
fi


FD_DEFAULT_OPTIONS="--hidden --no-ignore --exclude .git --exclude node_modules"
EZA_OPTIONS="--icons --tree --color=always {}"
BAT_OPTIONS="--color=always -n --line-range :500 {}"

export FZF_DEFAULT_OPTS="--style minimal --height 50% --border"
export FZF_CTRL_T_OPTS="--prompt 'All> ' \
  --header 'CTRL-D: Directories / CTRL-F: Files' \
  --preview '[[ -d {} ]] && eza $EZA_OPTIONS | head -200 || bat $BAT_OPTIONS' \
  --bind 'ctrl-d:change-prompt(Directories> )+reload(fd --type d $FD_DEFAULT_OPTIONS)' \
  --bind 'ctrl-f:change-prompt(Files> )+reload(fd --type f  $FD_DEFAULT_OPTIONS)' \
  --bind 'ctrl-a:change-prompt(All> )+reload(fd $FD_DEFAULT_OPTIONS)'"
