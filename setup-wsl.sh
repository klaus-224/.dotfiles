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
PKG_FILE="$DOTFILES_DIR/packages/windows.txt"

echo -e "${YELLOW}⚙️  Setting up your WSL environment with Homebrew...${RESET}"

# -----------------------------------------------------
#  Install Homebrew 
# -----------------------------------------------------
if ! command -v brew &>/dev/null; then
  echo -e "${YELLOW}Installing Homebrew...${RESET}"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> ~/.bashrc
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
else
  echo -e "${GREEN}Homebrew already installed.${RESET}"
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

# -----------------------------------------------------
#  Update brew
# -----------------------------------------------------
echo -e "${YELLOW}Updating Homebrew...${RESET}"
brew update

# -----------------------------------------------------
#  Install all packages listed in packages/windows.txt
# -----------------------------------------------------
if [[ ! -f "$PKG_FILE" ]]; then
  echo -e "${RED}❌ Package list not found at: $PKG_FILE${RESET}"
  exit 1
fi

echo -e "${YELLOW}Installing packages from ${BLUE}$PKG_FILE${RESET}"

while read -r pkg; do
  [[ -z "$pkg" || "$pkg" == \#* ]] && continue  # skip comments or empty lines

  if brew list --formula | grep -q "^${pkg}\$"; then
    echo -e "${GREEN}✔ $pkg already installed${RESET}"
  else
    echo -e "${YELLOW}→ Installing $pkg...${RESET}"
    brew install "$pkg" || echo -e "${RED}Failed to install $pkg${RESET}"
  fi
done < "$PKG_FILE"

brew cleanup

cd "$HOME/.dotfiles"

# -----------------------------------------------------
#  Symlink dotfiles using stow
# -----------------------------------------------------
if command -v stow >/dev/null 2>&1; then
  echo -e "${YELLOW}Linking dotfiles using stow...${RESET}"

  mkdir -p "$HOME/.config"
  stow --verbose -d "$DOTFILES_DIR/.config" -t "$HOME/.config" alacritty
  stow --verbose -d "$DOTFILES_DIR/.config" -t "$HOME/.config" nvim
  stow --verbose -d "$DOTFILES_DIR" -t "$HOME" zsh
  stow --verbose -d "$DOTFILES_DIR" -t "$HOME" tmux

  echo -e "${GREEN}Symlinking complete.${RESET}"
else
  echo -e "${RED}stow not found — please install and rerun this script.${RESET}"
  exit 1
fi

# -----------------------------------------------------
#  Oh My Zsh + Powerlevel10k + Plugins
# -----------------------------------------------------
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
  echo -e "${YELLOW}Installing Oh My Zsh...${RESET}"
  RUNZSH=no KEEP_ZSHRC=yes \
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
  echo -e "${GREEN}Oh My Zsh already installed.${RESET}"
fi

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

# Powerlevel10k
if [[ ! -d "$ZSH_CUSTOM/themes/powerlevel10k" ]]; then
  echo -e "${YELLOW}Installing Powerlevel10k...${RESET}"
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$ZSH_CUSTOM/themes/powerlevel10k"
fi

# Plugins
for plugin in zsh-autosuggestions zsh-syntax-highlighting; do
  case $plugin in
    zsh-autosuggestions)
      repo="https://github.com/zsh-users/zsh-autosuggestions"
      ;;
    zsh-syntax-highlighting)
      repo="https://github.com/zsh-users/zsh-syntax-highlighting.git"
      ;;
  esac

  if [[ ! -d "$ZSH_CUSTOM/plugins/$plugin" ]]; then
    echo -e "${YELLOW}Installing ${plugin}...${RESET}"
    git clone "$repo" "$ZSH_CUSTOM/plugins/$plugin"
  fi
done

# -----------------------------------------------------
#  Update .zshrc with Powerlevel10k and plugin references
# -----------------------------------------------------
ZSHRC="$HOME/.zshrc"
if ! grep -q "powerlevel10k" "$ZSHRC"; then
  echo 'ZSH_THEME="powerlevel10k/powerlevel10k"' >> "$ZSHRC"
fi

if ! grep -q "zsh-autosuggestions" "$ZSHRC"; then
  sed -i 's/^plugins=(/&zsh-autosuggestions zsh-syntax-highlighting /' "$ZSHRC" || true
fi

# -----------------------------------------------------
#  Source configs
# -----------------------------------------------------
echo -e "${YELLOW}Reloading configurations...${RESET}"
source "$HOME/.zshrc" || true
nvim --headless "+Lazy sync" +qa || true

# -----------------------------------------------------
#  Done
# -----------------------------------------------------
echo -e "${GREEN}WSL Dotfiles setup complete!${RESET}"
echo -e "${YELLOW}Restart your terminal or run \`exec zsh\` to start using your new shell.${RESET}"

