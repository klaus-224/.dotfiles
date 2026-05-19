typeset -U path PATH

export PNPM_HOME="$HOME/Library/pnpm"
export CARGO_HOME="$HOME/.cargo"
export LOCAL_BIN="/usr/local"
export NVM_DIR="$HOME/.nvm"

eval "$(starship init zsh)"

path=(
	"$HOME/.dotfiles/bin" # custom scripts
	"$HOME/.local/bin"    # binaries from other tools
	"$LOCAL_BIN/go/bin"   # go
	"$CARGO_HOME/bin"
	"$PNPM_HOME"
	"${path[@]}"
)

export PATH
