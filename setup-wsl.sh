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
echo -e "${YELLOW} Setting up your WSL environment...${RESET}"

# -----------------------------------------------------
#  Install git first (required to clone dotfiles)
# -----------------------------------------------------
echo -e "${YELLOW} Installing git...${RESET}"
sudo apt update
sudo apt install -y git

# -----------------------------------------------------
#  Clone dotfiles repo if needed
# -----------------------------------------------------
if [[ ! -d "$HOME/.dotfiles" ]]; then
  echo -e "${YELLOW} Cloning dotfiles...${RESET}"
  git clone git@github.com:klaus-224/.dotfiles.git "$HOME/.dotfiles"
else
  echo -e "${GREEN} Dotfiles already exist.${RESET}"
fi

cd "$HOME/.dotfiles"

# -----------------------------------------------------
#  Install other required packages from packages/windows.txt
# -----------------------------------------------------
PKG_FILE="$DOTFILES_DIR/packages/windows.txt"

if [[ ! -f "$PKG_FILE" ]]; then
  echo -e "${RED} Package file not found at $PKG_FILE${RESET}"
  exit 1
fi

echo -e "${YELLOW} Installing required packages from ${BLUE}$PKG_FILE${RESET}"

# Update package lists and install packages
sudo apt update && sudo apt upgrade -y

while read -r pkg; do
  [[ -z "$pkg" || "$pkg" == \#* ]] && continue
  if dpkg -s "$pkg" &> /dev/null; then
    echo -e "${GREEN} Package '$pkg' already installed.${RESET}"
  else
    echo -e "${YELLOW}→ Installing $pkg...${RESET}"
    sudo apt install -y "$pkg" && echo -e "${GREEN} Installed $pkg${RESET}" || echo -e "${RED} Failed to install $pkg${RESET}"
  fi
done < "$PKG_FILE"

# -----------------------------------------------------
#  Symlink dotfiles using stow
# -----------------------------------------------------
if command -v stow >/dev/null 2>&1; then
  echo -e "${YELLOW} Linking necessary dotfiles using stow...${RESET}"

  # Symlink core configs:
	stow --verbose -d "$HOME/.dotfiles/.config" -t "$HOME/.config" alacritty
	stow --verbose -d "$HOME/.dotfiles/.config" -t "$HOME/.config" nvim
  stow --verbose zsh               
  stow --verbose tmux             

  echo -e "${GREEN} Symlinking complete.${RESET}"
else
  echo -e "${RED} stow not found — please install it and rerun this script.${RESET}"
fi

# -----------------------------------------------------
#  Install Alacritty on Windows via winget
# -----------------------------------------------------
echo -e "${YELLOW} Installing Alacritty on Windows...${RESET}"
powershell.exe -Command 'winget install --id Alacritty.Alacritty -e --source winget' || \
  echo -e "${RED} Failed to install Alacritty via winget (maybe already installed).${RESET}"

# -----------------------------------------------------
#  Oh My Zsh + Plugins + Powerlevel10k
# -----------------------------------------------------
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
  RUNZSH=no KEEP_ZSHRC=yes \
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$ZSH_CUSTOM/themes/powerlevel10k" 2>/dev/null || true
git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions" 2>/dev/null || true
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" 2>/dev/null || true

TPM_DIR="$HOME/.tmux/plugins/tpm"
[[ ! -d "$TPM_DIR" ]] && git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"

echo -e "${GREEN}WSL + Alacritty setup complete!${RESET}"
echo -e "${YELLOW}Launch Alacritty on Windows and set its shell to start WSL (Ubuntu).${RESET}"

