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
#  Install Homebrew
# -----------------------------------------------------
if ! command -v brew >/dev/null 2>&1; then
  echo -e "${YELLOW}Homebrew not found, installing...${RESET}"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv)"
else
  echo -e "${GREEN}Homebrew already installed.${RESET}"
fi

# -----------------------------------------------------
#  Install git (required to clone dotfiles)
# -----------------------------------------------------
if ! command -v git >/dev/null 2>&1; then
  echo -e "${YELLOW}Installing git...${RESET}"
  brew install git
else
  echo -e "${GREEN}git already installed.${RESET}"
fi

# -----------------------------------------------------
#  Clone dotfiles repo
# -----------------------------------------------------
if [[ ! -d "$HOME/.dotfiles" ]]; then
  echo -e "${YELLOW}Cloning dotfiles repository...${RESET}"
  git clone git@github.com:klaus-224/.dotfiles.git "$HOME/.dotfiles"
else
  echo -e "${GREEN}Dotfiles repository already exists at ~/.dotfiles.${RESET}"
fi

cd "$HOME/.dotfiles"

# -----------------------------------------------------
#  Install required packages (after git and dotfiles)
# -----------------------------------------------------
PKG_FILE="$DOTFILES_DIR/packages/macos.txt"
if [[ ! -f "$PKG_FILE" ]]; then
  echo -e "${RED}Package file not found at $PKG_FILE${RESET}"
  exit 1
fi

echo -e "${YELLOW}Installing required packages from ${BLUE}$PKG_FILE${RESET}"
while read -r pkg; do
  [[ -z "$pkg" || "$pkg" == \#* ]] && continue
  if brew list --formula | grep -q "^$pkg\$"; then
    echo -e "${GREEN}$pkg already installed.${RESET}"
  else
    echo -e "${YELLOW}→ Installing $pkg...${RESET}"
    brew install "$pkg" && echo -e "${GREEN}Installed $pkg${RESET}" || echo -e "${RED}Failed to install $pkg${RESET}"
  fi
done < "$PKG_FILE"

# -----------------------------------------------------
#  Symlink dotfiles using stow
# -----------------------------------------------------
if command -v stow >/dev/null 2>&1; then
  echo -e "${YELLOW}Linking dotfiles using stow...${RESET}"
  stow zsh
  stow tmux
  stow .config/alacritty
  stow .config/nvim
  echo -e "${GREEN}Dotfiles linked successfully.${RESET}"
else
  echo -e "${RED}stow not found — please install it and rerun this script.${RESET}"
fi

# -----------------------------------------------------
#  Oh My Zsh
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
THEME_DIR="$HOME/.oh-my-zsh/custom/themes/powerlevel10k"
if [[ ! -d "$THEME_DIR" ]]; then
  echo -e "${YELLOW}Installing Powerlevel10k theme...${RESET}"
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$THEME_DIR"
else
  echo -e "${GREEN}Powerlevel10k already installed.${RESET}"
fi

# -----------------------------------------------------
#  ZSH Plugins
# -----------------------------------------------------
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

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

# -----------------------------------------------------
#  Ghostty Terminal
# -----------------------------------------------------
if ! brew list --cask | grep -q "^ghostty\$"; then
  echo -e "${YELLOW}Installing Ghostty terminal...${RESET}"
  brew install --cask ghostty
else
  echo -e "${GREEN}Ghostty already installed.${RESET}"
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

