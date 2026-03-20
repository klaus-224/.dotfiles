# --------------------------------------------------
# 40-aliases.zsh
# Purpose:
#   Define short, memorable command aliases.
#
# Responsibilities:
#   - Navigation shortcuts
#   - Command replacements (ls → eza, etc.)
#
# Rules:
#   - Aliases only
#   - Prefer functions for anything non-trivial
#   - No environment or PATH changes
# --------------------------------------------------

# navigation
alias cdh="cd ~"
alias cdd="cd ~/.dotfiles"
alias cdc="cd ~/code"
alias cdnc="cd ~/.dotfiles/nvim/.config/nvim"
alias d="dirs -v"

# editors
alias vi="nvim"
alias sz="source ~/.zshrc"

# eza
alias ls="eza --long --all --group-directories-first --no-user --no-time --icons"
alias lst="eza --tree --long --all --group-directories-first --no-user --no-time --icons"

# tmux
alias tkw="tmux killw"
alias tkp="tmux killp"

# python
alias python="python3"
alias pip="pip3"
alias pyenv-create="python -m venv .venv"
alias pyenv-activate="source .venv/bin/activate"

# git
alias lg="lazygit"
alias gs="git status"
alias ga="git add"
alias gc="git commit"
alias gp="git push"
alias gf="git fetch"
alias gpr="gh pr create"

# graphivz
alias D2S="dot -Tsvg ${1} > ${2}"
