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

# editors
alias nv="nvim"
alias srczsh="source ~/.zshrc"

# eza
alias ls="eza --long --all --group-directories-first --no-user --no-time --icons"

# tmux
alias ta="tmux a"
alias tkw="tmux killw"
alias tkp="tmux killp"

# python
alias python="python3"
alias pip="pip3"
alias pyenv-create="python -m venv .venv"
alias pyenv-activate="source .venv/bin/activate"

