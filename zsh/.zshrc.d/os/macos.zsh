# --------------------------------------------------
# os/macos.zsh
# Purpose:
#   macOS-only shell configuration.
#
# Responsibilities:
#   - Homebrew environment
#   - macOS-specific PATHs or tools
#
# Rules:
#   - Must not affect Linux
# --------------------------------------------------

# homebrew path
BREW_BIN="$(command -v brew || true)"
if [[ -n "$BREW_BIN" ]]; then
	eval "$($BREW_BIN shellenv)"
fi
