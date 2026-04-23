# --------------------------------------------------
# 20-path.zsh
# Purpose:
#   Define and normalize PATH entries.
#
# Responsibilities:
#   - Add user-level tool directories to PATH
#   - Keep PATH logic isolated and predictable
#
# Rules:
#   - PATH changes only
#   - No tool initialization
#   - No aliases or functions
# --------------------------------------------------

typeset -U path PATH

export PNPM_HOME="$HOME/Library/pnpm"
export CARGO_HOME="${CARGO_HOME:-$HOME/.cargo}"
export LOCAL_BIN="/usr/local"

path=(
	"$HOME/.dotfiles/bin" # custom scripts
	"$HOME/.local/bin"    # binaries from other tools
	"$LOCAL_BIN/go/bin"   # go
	"$CARGO_HOME/bin"
	"$PNPM_HOME"
	"${path[@]}"
)

export PATH
