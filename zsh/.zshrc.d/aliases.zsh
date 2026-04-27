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

# git
alias lg="lazygit"

# launch dadbodui
alias dbui="vi -c DBUI"

# smolvm
alias svmrust="smolfile_render \${DOTFILES_HOME}/smolvm/rust-dev.smolfile.tmpl \${CODE_DIR}/smolvm/rust-dev.smolfile"
alias svmc="smolvm machine create"
alias svmd="smolvm machine delete"
alias svmls="smolvm machine ls"
alias svmstart="smolvm machine start"
alias svmstop="smolvm machine stop"
alias svmex="smolvm machine exec"
