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
export DOTFILES_HOME="${DOTFILES_HOME:-$DOTFILES_DIR}"
echo -e "${YELLOW}Setting up macOS dotfiles environment...${RESET}"

# -----------------------------------------------------
#  Homebrew bootstrap
# -----------------------------------------------------
if ! command -v brew >/dev/null 2>&1; then
	echo -e "${YELLOW}Homebrew not found. Installing...${RESET}"
	/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

	BREW_PATH="/opt/homebrew/bin/brew"
	if [[ -x $BREW_PATH ]]; then
		eval "$("$BREW_PATH" shellenv)"
	else
		echo -e "${RED}Homebrew not found at $BREW_PATH${RESET}"
		exit 1
	fi
else
	echo -e "${GREEN}Homebrew already installed.${RESET}"
fi

echo -e "${YELLOW}Updating Homebrew...${RESET}"
brew update

# -----------------------------------------------------
#  Install packages via unified Brewfile
# -----------------------------------------------------
echo -e "${YELLOW}Installing packages via unified Brewfile...${RESET}"
"$DOTFILES_DIR/scripts/install-brew-packages.sh"

echo -e "${GREEN}Brew bundle complete.${RESET}"

# -----------------------------------------------------
#  Rust/Cargo bootstrap + cargo package sync
# -----------------------------------------------------
if ! command -v cargo >/dev/null 2>&1; then
	if command -v rustup-init >/dev/null 2>&1; then
		echo -e "${YELLOW}Installing Rust toolchain via rustup-init...${RESET}"
		rustup-init -y --profile minimal --default-toolchain stable --no-modify-path
	else
		echo -e "${YELLOW}rustup-init not found; skipping Rust toolchain bootstrap.${RESET}"
	fi
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
#  ZSH Plugins
# -----------------------------------------------------
[[ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]] &&
	git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"

[[ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]] &&
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
echo -e "\nOptional agent setup:"
echo -e "  ${YELLOW}./scripts/setup-codex-cli.sh${RESET}"
echo -e "  ${YELLOW}./scripts/setup-copilot-cli.sh${RESET}"
echo -e "\nIf this is a fresh setup, restart your terminal."
