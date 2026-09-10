# --------------------------------------------------
#  entry point for zsh configuration
# --------------------------------------------------
[[ -n "${ZSH_VERSION:-}" ]] || return 0
emulate -LR zsh

typeset -U path PATH

path=(
	"$HOME/.dotfiles/bin"
	"$HOME/.local/bin"  
	"$LOCAL_BIN/go/bin"  
	"${path[@]}"
)

export PATH

eval "$(starship init zsh)"

# runs opencode from .dotfiles
opencode() {
  XDG_CONFIG_HOME="$HOME/.dotfiles/.config" command opencode "$@"
}

# Source modular config
for file in "$DOTFILES_HOME"/zsh/.zshrc.d/*.zsh; do
	[[ -f "$file" ]] || continue
	source "$file"
done

# Completions
fpath=(
  "$ZSH_COMPLETIONS"
  "$HOME/.zsh/completions"
  $fpath
)

mkdir -p "$HOME/.cache/zsh"
autoload -Uz compinit
compinit -d "$HOME/.cache/zsh/zcompdump-$ZSH_VERSION"

# Plugins
source "$ZSH_AUTOSUGGESTIONS"
source "$ZSH_SYNTAX_HIGHLIGHTING"

# options
setopt AUTO_PUSHD
setopt PUSHD_IGNORE_DUPS
setopt PUSHD_SILENT
