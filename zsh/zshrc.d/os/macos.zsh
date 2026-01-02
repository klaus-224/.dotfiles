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
eval "$(/opt/homebrew/bin/brew shellenv)"
