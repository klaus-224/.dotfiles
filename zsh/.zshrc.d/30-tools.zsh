# --------------------------------------------------
# 30-tools.zsh
# Purpose:
#   Initialize CLI tools that need shell hooks.
#
# Examples:
#   - nvm
#   - fzf
#   - language version managers
#
# Rules:
#   - Tools must already be installed
#   - No package installation here
#   - No aliases
# --------------------------------------------------

# fzf
eval "$(fzf --zsh)"

# fzf-git
if [[ -s "$HOME/.dotfiles/scripts/fzf-git.sh" ]]; then
	source "$HOME/.dotfiles/scripts/fzf-git.sh"
fi


export FZF_DEFAULT_OPTS="--style minimal --height 50% --border"
export FZF_CTRL_T_OPTS="--prompt 'All> ' \
  --header 'CTRL-D: Directories / CTRL-F: Files' \
  --preview '[[ -d {} ]] && eza --icons --tree --color=always {} | head -200 || bat --color=always -n --line-range :500 {}' \
  --bind 'ctrl-d:change-prompt(Directories> )+reload(fd --type d --hidden --exclude .git)' \
  --bind 'ctrl-f:change-prompt(Files> )+reload(fd --type f --hidden --exclude .git)' \
  --bind 'ctrl-a:change-prompt(All> )+reload(fd --hidden --exclude .git)'"

# nvm
export NVM_DIR="$HOME/.nvm"

if [[ -s "/opt/homebrew/opt/nvm/nvm.sh" ]]; then
  source "/opt/homebrew/opt/nvm/nvm.sh"
fi
