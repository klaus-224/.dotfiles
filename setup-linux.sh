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

echo -e "${YELLOW}⚙️  Setting up your WSL environment with Homebrew...${RESET}"

# -----------------------------------------------------
#  Homebrew
# -----------------------------------------------------
if ! command -v brew &>/dev/null; then
	echo -e "${YELLOW}Installing Homebrew...${RESET}"
	/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

BREW_PATH="$(command -v brew || true)"
if [[ -x "$BREW_PATH" ]]; then
	eval "$("$BREW_PATH" shellenv)"
else
	echo -e "${RED}Unable to locate Homebrew executable.${RESET}"
	exit 1
fi

# -----------------------------------------------------
#  Update brew
# -----------------------------------------------------
echo -e "${YELLOW}Updating Homebrew...${RESET}"
brew update

# -----------------------------------------------------
#  Install packages via unified Brewfile
# -----------------------------------------------------
echo -e "${YELLOW}Installing packages via unified Brewfile...${RESET}"
"$DOTFILES_DIR/scripts/install-brew-packages.sh"
brew cleanup

echo -e "${GREEN}Brew bundle complete.${RESET}"

# -----------------------------------------------------
#  Rust/Cargo bootstrap + cargo package sync
# -----------------------------------------------------
if ! command -v cargo >/dev/null 2>&1 && command -v rustup-init >/dev/null 2>&1; then
	echo -e "${YELLOW}Installing Rust toolchain via rustup-init...${RESET}"
	rustup-init -y --profile minimal --default-toolchain stable --no-modify-path
fi

if [[ -f "$HOME/.cargo/env" ]]; then
	# shellcheck disable=SC1090
	source "$HOME/.cargo/env"
fi
export PATH="$HOME/.cargo/bin:$PATH"

if command -v cargo >/dev/null 2>&1; then
	echo -e "${YELLOW}Syncing cargo packages from packages/cargo.txt...${RESET}"
	"$DOTFILES_DIR/scripts/sync-cargo-packages.sh" sync
else
	echo -e "${YELLOW}cargo not found; skipping cargo package sync.${RESET}"
fi

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
#  TMUX Plugin Manager
# -----------------------------------------------------
TPM_DIR="$HOME/.tmux/plugins/tpm"
if [[ ! -d "$TPM_DIR" ]]; then
	echo -e "${YELLOW}Installing TPM...${RESET}"
	git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
fi

# -----------------------------------------------------
#  Optional zsh plugin dirs (no framework required)
# -----------------------------------------------------
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.zsh/plugins}"
mkdir -p "$ZSH_CUSTOM/plugins"

# -----------------------------------------------------
#  Source configs
# -----------------------------------------------------
echo -e "${YELLOW}Reloading configurations...${RESET}"
nvim --headless "+Lazy sync" +qa || true

# -----------------------------------------------------
#  Done
# -----------------------------------------------------
echo -e "${GREEN}WSL Dotfiles setup complete!${RESET}"
echo -e "${YELLOW}Restart your terminal or run \`exec zsh\` to start using your new shell.${RESET}"
