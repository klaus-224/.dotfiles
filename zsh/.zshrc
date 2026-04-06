# --------------------------------------------------
#	.zshrc
# Purpose:
# 	- entry point for zsh configuration
# 	- loops through zsh fragements in /.zshrc.d and
# 		sources them
# --------------------------------------------------
[[ -n "${ZSH_VERSION:-}" ]] || return 0
emulate -LR zsh

# move zshcompdump to ~/.cache/zsh/ so that it's not annoying
autoload -Uz compinit
compinit -d ~/.cache/zsh/zcompdump-$ZSH_VERSION
# add to path
eval "$(codex completion zsh)"
eval "$(starship init zsh)"

# source all config files
for file in "$HOME/.zshrc.d/"*.zsh; do
	[ -f "$file" ] && source "$file"
done

# source custom env vars
source "$HOME/.zshenv"
# Options
setopt AUTO_PUSHD
setopt PUSHD_IGNORE_DUPS
setopt PUSHD_SILENT
