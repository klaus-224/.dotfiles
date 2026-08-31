# navigation
alias cdh="cd ~"
alias cdd="cd ~/.dotfiles"
alias cdc="cd ~/code"
alias cdnc="cd ~/.dotfiles/nvim/.config/nvim"

alias ctx="ctx7"
alias oc="opencode"
alias lg="lazygit"
alias tkw="tmux killw"
alias tkp="tmux killp"
alias hq="harlequin"

# editors
alias vi="nvim"
alias sz="source ~/.zshrc"

# eza
alias ls="eza --long --no-time --no-user --no-permissions --all --group-directories-first --icons"
alias lst="eza --tree --long --all --group-directories-first --no-user --no-time --icons"

# smolvm
alias svmrust="smolfile_render \${DOTFILES_HOME}/smolvm/rust-dev.smolfile.tmpl \${CODE_DIR}/smolvm/rust-dev.smolfile"
alias svmc="smolvm machine create"
alias svmd="smolvm machine delete"
alias svmls="smolvm machine ls"
alias svmstart="smolvm machine start"
alias svmstop="smolvm machine stop"
alias svmex="smolvm machine exec"

# suffix alias
alias -s {js,json,env,html,css,toml,ts,tsx,rs}="bat"
alias -s md="glow -t"
alias -s {mov,png,mp4,pdf}="open"
