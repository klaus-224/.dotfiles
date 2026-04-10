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

path=(
	"$HOME/.dotfiles/bin" # custom scripts
	"$CARGO_HOME/bin"
	"$PNPM_HOME"
	"${path[@]}"
)

export PATH
