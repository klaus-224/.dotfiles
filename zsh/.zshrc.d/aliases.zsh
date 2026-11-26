# navigation
alias cdh="cd ~ "

unalias cdx 2>/dev/null
cdx() { cd ~/.config/"$1"; }

unalias cdd 2>/dev/null
cdd() { cd ~/.dotfiles/"$1"; }

unalias cdc 2>/dev/null
cdc() { cd ~/code/"$1"; }

alias cpdir="cp -r"

# ctx is a compiled helper from scripts/, also available to noninteractive tools.
alias oc="opencode"
alias tkw="tmux killw"
alias tkp="tmux killp"

# editors
alias vi="nvim"
alias sz="source ~/.zshrc"

# eza
alias ls="eza --long --no-time --no-user --no-permissions --all --group-directories-first --icons"
alias lst="eza --tree --long --all --group-directories-first --no-user --no-time --icons"

# suffix alias
# alias -s {js,json,env,html,css,toml,ts,tsx,rs}="bat"
alias -s {mov,png,mp4,pdf}="open"
alias man='MANPAGER="nvim +Man!" command man'
