# OH-MY-ZSH
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"
plugins=(git docker-compose docker copyfile)
source $ZSH/oh-my-zsh.sh
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# NVM
export NVM_DIR="$HOME/.nvm"
[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"  # This loads nvm
[ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"  # This loads nvm bash_completion
source ~/.nvm/nvm.sh

# PNPM
export PNPM_HOME="/Users/rohineshram/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac

# FZF
eval	"$(fzf --zsh)"
export FZF_DEFAULT_COMMAND="fd --hidden --strip-cwd-prefix --exclude .git "
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND="fd --type=d --hidden --strip-cwd-prefix --exclude .git"
export FZF_DEFAULT_OPTS="--height 50% --layout=default --border --color=hl:#2dd4bf"
# Setup fzf previews
export FZF_CTRL_T_OPTS="--preview 'bat --color=always -n --line-range :500 {}'"
export FZF_ALT_C_OPTS="--preview 'eza --icons=always --tree --color=always {} | head -200'"
# fzf preview for tmux
export FZF_TMUX_OPTS=" -p90%,70% "

# ZSH PLUGINS
source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

## ALIASES
# general
alias cdh="cd $HOME" # change dir to home
alias cdd="cd $HOME/.dotfiles" # change dir to .dotfiles
alias cdd="cdc $HOME/.dotfiles" # change dir to code
alias srczsh="source $HOME/.zshrc"
alias nv="nvim"

# eza - ls replacement
alias ls="eza --long --all --group-directories-first --no-user --no-time --color=always --icons=always" 

# ollama
alias ollama-get="docker run -d -v ollama:/root/.ollama -p 11434:11434 --name ollama ollama/ollama"
alias ollama-start="docker start ollama"
alias ollama="docker exec -it ollama ollama"

# tmux
alias ta="tmux a"
alias tkw="tmux killw"
alias tkp="tmux killp"


### MANAGED BY RANCHER DESKTOP START (DO NOT EDIT)
export PATH="/Users/rohineshram/.rd/bin:$PATH"
### MANAGED BY RANCHER DESKTOP END (DO NOT EDIT)
