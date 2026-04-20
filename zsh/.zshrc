# --------------------------------------------------
#	.zshrc
# Purpose:
# 	- entry point for zsh configuration
# 	- loops through zsh fragements in /.zshrc.d and
# 		sources them
# --------------------------------------------------
[[ -n "${ZSH_VERSION:-}" ]] || return 0
emulate -LR zsh

# source custom env vars
source "$HOME/.zshenv"
# add to path
eval "$(starship init zsh)"

# source all config files
for file in "$HOME/.zshrc.d/"*.zsh; do
	[ -f "$file" ] && source "$file"
done

# move zshcompdump to ~/.cache/zsh/ so that it's not annoying
autoload -Uz compinit
compinit -d ~/.cache/zsh/zcompdump-$ZSH_VERSION

# Options
setopt AUTO_PUSHD
setopt PUSHD_IGNORE_DUPS
setopt PUSHD_SILENT


# >>> opentmux >>>
export OPENCODE_PORT=4096
alias opencode='opentmux'
# <<< opentmux <<<


# >>> opencode-agent-tmux >>>
export OPENCODE_PORT=4096
alias opencode='opencode-tmux'
# <<< opencode-agent-tmux <<<
