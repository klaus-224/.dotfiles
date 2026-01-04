#!/usr/bin/env bash
set -euo pipefail

# -----------------------------------------------------
#  Colors for output
# -----------------------------------------------------
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
BLUE="\033[1;34m"
RED="\033[0;31m"
RESET="\033[0m"

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo -e "${YELLOW}Setting up macOS dotfiles environment...${RESET}"

# -----------------------------------------------------
#  Homebrew bootstrap
# -----------------------------------------------------
if ! command -v brew >/dev/null 2>&1; then
  echo -e "${YELLOW}Homebrew not found. Installing...${RESET}"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

	BREW_PATH="/opt/homebrew/bin/brew"
  if [[ -x $BREW_PATH ]]; then
    eval "$($BREW_PATH shellenv)"
	else
  	echo -e "${RED}Homebrew not found at $BREW_PATH${RESET}"
  	exit 1
	if
else
  echo -e "${GREEN}Homebrew already installed.${RESET}"
fi

echo -e "${YELLOW}Updating Homebrew...${RESET}"
brew update

# -----------------------------------------------------
#  Install packages via Brewfile (common + macos)
# -----------------------------------------------------
BREW_DIR="$DOTFILES_DIR/brewfiles"
COMMON="$BREW_DIR/Brewfile.common"
MACOS="$BREW_DIR/Brewfile.macos"

if [[ ! -f "$COMMON" ]]; then
  echo -e "${RED}Missing Brewfile: $COMMON${RESET}"
  exit 1
fi
if [[ ! -f "$MACOS" ]]; then
  echo -e "${RED}Missing Brewfile: $MACOS${RESET}"
  exit 1
fi

echo -e "${YELLOW}Installing packages via Brewfiles...${RESET}"
TMP_BREWFILE="$(mktemp)"
cat "$COMMON" "$MACOS" > "$TMP_BREWFILE"
brew bundle --file "$TMP_BREWFILE"
rm -f "$TMP_BREWFILE"

echo -e "${GREEN}Brew bundle complete.${RESET}"

# -----------------------------------------------------
#  Symlink dotfiles using stow
# -----------------------------------------------------
if command -v stow >/dev/null 2>&1; then
  echo -e "${YELLOW}Linking dotfiles using stow...${RESET}"
  stow zsh
  stow tmux
  stow nvim
  stow ghostty
  echo -e "${GREEN}Dotfiles linked successfully.${RESET}"
else
  echo -e "${RED}stow not found — please install it and rerun this script.${RESET}"
fi

# -----------------------------------------------------
#  oh-my-zsh
# -----------------------------------------------------
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
  echo -e "${YELLOW}Installing Oh My Zsh...${RESET}"
  RUNZSH=no KEEP_ZSHRC=yes \
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
  echo -e "${GREEN}Oh My Zsh already installed.${RESET}"
fi

# -----------------------------------------------------
#  Powerlevel10k
# -----------------------------------------------------
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
THEME_DIR="$ZSH_CUSTOM/themes/powerlevel10k"
if [[ ! -d "$THEME_DIR" ]]; then
  echo -e "${YELLOW}Installing Powerlevel10k theme...${RESET}"
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$THEME_DIR"
else
  echo -e "${GREEN}Powerlevel10k already installed.${RESET}"
fi

# -----------------------------------------------------
#  ZSH Plugins
# -----------------------------------------------------
[[ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]] && \
  git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"

[[ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]] && \
  git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"

# -----------------------------------------------------
#  TMUX Plugin Manager
# -----------------------------------------------------
TPM_DIR="$HOME/.tmux/plugins/tpm"
[[ ! -d "$TPM_DIR" ]] && git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"

# -----------------------------------------------------
#  FZF post-install
# -----------------------------------------------------
if command -v fzf >/dev/null 2>&1; then
  echo -e "${YELLOW}Running fzf install script...${RESET}"
  "$(brew --prefix)"/opt/fzf/install --all --no-bash --no-fish
fi

if command -v duti >/dev/null 2>&1; then
  echo -e "${YELLOW}Setting Ghostty as default terminal for .command files...${RESET}"
  duti -s com.mitchellh.ghostty .command all
else
  echo -e "${YELLOW}'duti' not found — install it to set Ghostty as default terminal.${RESET}"
fi

# -----------------------------------------------------
#  Completion Message
# -----------------------------------------------------
echo -e "\n${GREEN}Setup complete!${RESET}"
echo -e "Tmux shortcuts:"
echo -e "  • ${YELLOW}ctrl-s + r${RESET} — reload tmux"
echo -e "  • ${YELLOW}ctrl-s + ctrl-I${RESET} — install TPM plugins"
echo -e "\nLaunch Ghostty via Spotlight or run:"
echo -e "  ${YELLOW}open -a Ghostty${RESET}"
echo -e "\nIf this is a fresh setup, restart your terminal."

