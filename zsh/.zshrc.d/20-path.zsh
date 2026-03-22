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

# pnpm
export PNPM_HOME="$HOME/Library/pnpm"
[[ ":$PATH:" != *":$PNPM_HOME:"* ]] && PATH="$PNPM_HOME:$PATH"

# cargo
export CARGO_HOME="${CARGO_HOME:-$HOME/.cargo}"
[[ ":$PATH:" != *":$CARGO_HOME/bin:"* ]] && PATH="$CARGO_HOME/bin:$PATH"
