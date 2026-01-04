# --------------------------------------------------
# 10-oh-my-zsh.zsh
# Purpose:
#   Initialize Oh My Zsh and the shell theme.
#
# Responsibilities:
#   - Define $ZSH location
#   - Select and load Powerlevel10k
#   - Enable oh-my-zsh plugins
#   - Source ~/.p10k.zsh if present
#
# Rules:
#   - No aliases
#   - No PATH changes
#   - No tool installs
# --------------------------------------------------

export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="powerlevel10k/powerlevel10k"

plugins=(
					git
					docker-compose 
					docker
					copyfile
					zsh-autosuggestions
					zsh-syntax-highlighting
				)

[[ -r "$ZSH/oh-my-zsh.sh" ]] && source "$ZSH/oh-my-zsh.sh"
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh
