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

# wtmb <feature-branch>: merge current branch into <feature-branch>, creating it if absent
function wtmb() {
    local feature=${1:?usage: wtmb <feature-branch>}
    local current
    current=$(git rev-parse --abbrev-ref HEAD) || return 1
    git fetch origin --quiet 2>/dev/null || true
    if ! git show-ref --verify --quiet "refs/heads/${feature}"; then
        echo "Branch '${feature}' not found. Creating from current HEAD..."
        git branch "${feature}" || return 1
    fi
    git checkout "${feature}" || return 1
    git merge "${current}" --no-ff -m "merge ${current} into ${feature}"
}

# smolvm
alias svmrust="smolfile_render \${DOTFILES_HOME}/smolvm/rust-dev.smolfile.tmpl \${CODE_DIR}/smolvm/rust-dev.smolfile"
alias svmc="smolvm machine create"
alias svmd="smolvm machine delete"
alias svmls="smolvm machine ls"
alias svmstart="smolvm machine start"
alias svmstop="smolvm machine stop"
alias svmex="smolvm machine exec"

# misc
alias awake='caffeinate -dimsu &'
alias sleep-ok='pkill caffeinate'

# alias for custom scripts
alias learnings='learnings_store'
alias plan='plan_store'
alias session='session_reader'
