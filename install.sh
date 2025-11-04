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

# -----------------------------------------------------
#  Setup
# -----------------------------------------------------
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo -e "${YELLOW}🔧 Setting up your macOS dotfiles environment...${RESET}"

# -----------------------------------------------------
# 	Homebrew
# -----------------------------------------------------
if ! command -v brew >/dev/null 2>&1; then
  echo -e "${YELLOW} Homebrew not found, installing...${RESET}"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv)"
else
  echo -e "${GREEN} Homebrew already installed.${RESET}"
fi

# -----------------------------------------------------
#  Install required packages
# -----------------------------------------------------
PKG_FILE="$DOTFILES_DIR/packages/macos.txt"

if [[ ! -f "$PKG_FILE" ]]; then
  echo -e "${RED} Package file not found at $PKG_FILE${RESET}"
  exit 1
fi

echo -e "${YELLOW} Installing required packages from ${BLUE}$PKG_FILE${RESET}"

while read -r pkg; do
  [[ -z "$pkg" || "$pkg" == \#* ]] && continue
  if brew list --formula | grep -q "^$pkg\$"; then
    echo -e "${GREEN}  $pkg already installed.${RESET}"
  else
    echo -e "${YELLOW}→ Installing $pkg...${RESET}"
    brew install "$pkg" && echo -e "${GREEN} Installed $pkg${RESET}" || echo -e "${RED} Failed to install $pkg${RESET}"
  fi
done < "$PKG_FILE"

# -----------------------------------------------------
#  Clone dotfiles if missing
# -----------------------------------------------------
if [[ ! -d "$HOME/.dotfiles" ]]; then
  echo -e "${YELLOW} Cloning dotfiles repository...${RESET}"
  git clone git@github.com:klaus-224/.dotfiles.git "$HOME/.dotfiles"
else
  echo -e "${GREEN} Dotfiles repository already exists at ~/.dotfiles.${RESET}"
fi

cd "$HOME/.dotfiles"

# -----------------------------------------------------
#  Symlink dotfiles using stow
# -----------------------------------------------------
if command -v stow >/dev/null 2>&1; then
  echo -e "${YELLOW} Linking dotfiles using stow...${RESET}"
  stow .
  echo -e "${GREEN} Dotfiles linked successfully.${RESET}"
else
  echo -e "${RED} stow not found — please install it and rerun this script.${RESET}"
fi

# -----------------------------------------------------
#  Oh My Zsh
# -----------------------------------------------------
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
  echo -e "${YELLOW} Installing Oh My Zsh...${RESET}"
  RUNZSH=no KEEP_ZSHRC=yes \
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
  echo -e "${GREEN} Oh My Zsh already installed.${RESET}"
fi

# -----------------------------------------------------
#  Powerlevel10k theme
# -----------------------------------------------------
THEME_DIR="$HOME/.oh-my-zsh/custom/themes/powerlevel10k"
if [[ ! -d "$THEME_DIR" ]]; then
  echo -e "${YELLOW} Installing Powerlevel10k theme...${RESET}"
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$THEME_DIR"
else
  echo -e "${GREEN} Powerlevel10k already installed.${RESET}"
fi

# -----------------------------------------------------
#  ZSH Plugins
# -----------------------------------------------------
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]]; then
  echo -e "${YELLOW} Installing zsh-autosuggestions...${RESET}"
  git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
else
  echo -e "${GREEN} zsh-autosuggestions already installed.${RESET}"
fi

if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]]; then
  echo -e "${YELLOW} Installing zsh-syntax-highlighting...${RESET}"
  git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
else
  echo -e "${GREEN} zsh-syntax-highlighting already installed.${RESET}"
fi

# -----------------------------------------------------
#  TMUX Plugin Manager
# -----------------------------------------------------
TPM_DIR="$HOME/.tmux/plugins/tpm"
if [[ ! -d "$TPM_DIR" ]]; then
  echo -e "${YELLOW} Installing tmux plugin manager...${RESET}"
  git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
else
  echo -e "${GREEN} tmux plugin manager already installed.${RESET}"
fi

# -----------------------------------------------------
#  FZF post-install setup
# -----------------------------------------------------
if command -v fzf >/dev/null 2>&1; then
  echo -e "${YELLOW} Running fzf install script...${RESET}"
  "$(brew --prefix)"/opt/fzf/install --all --no-bash --no-fish
fi

# -----------------------------------------------------
#  Ghostty Terminal setup
# -----------------------------------------------------
if ! brew list --cask | grep -q "^ghostty\$"; then
  echo -e "${YELLOW} Installing Ghostty terminal...${RESET}"
  brew install --cask ghostty
else
  echo -e "${GREEN} Ghostty already installed.${RESET}"
fi

# Try to set Ghostty as the default terminal app for .command files
if command -v duti >/dev/null 2>&1; then
  echo -e "${YELLOW} Setting Ghostty as default terminal for .command files...${RESET}"
  # Ghostty bundle ID: com.mitchellh.ghostty
  duti -s com.mitchellh.ghostty .command all
  echo -e "${GREEN} Ghostty set as default terminal.${RESET}"
else
  echo -e "${YELLOW} 'duti' not found — install it to set Ghostty as default terminal.${RESET}"
  echo -e "${YELLOW}  → brew install duti${RESET}"
fi

# -----------------------------------------------------
# Completion Message
# -----------------------------------------------------
echo -e "\n${GREEN} Setup complete!${RESET}"
echo -e "Here are some useful tmux shortcuts:"
echo -e "  • ${YELLOW}ctrl-s + r${RESET} — reload tmux"
echo -e "  • ${YELLOW}ctrl-s + ctrl-I${RESET} — install TPM plugins"
echo -e "\nLaunch Ghostty from Spotlight or run:"
echo -e "  ${YELLOW}open -a Ghostty${RESET}"
echo -e "\nIf this is a fresh setup, restart your terminal."

