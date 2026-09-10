# --------------------------------------------------
#  entry point for zsh configuration
# --------------------------------------------------
[[ -n "${ZSH_VERSION:-}" ]] || return 0
emulate -LR zsh

# source custom env vars
# shellcheck source=/dev/null
source "$HOME/.zshenv"

typeset -U path PATH

export PNPM_HOME="$HOME/Library/pnpm"
export CARGO_HOME="$HOME/.cargo"
export LOCAL_BIN="/usr/local"
export NVM_DIR="$HOME/.nvm"

path=(
	"$HOME/.dotfiles/bin"
	"$HOME/.local/bin"  
	"$LOCAL_BIN/go/bin"  
	"$CARGO_HOME/bin"
	"$PNPM_HOME"
	"${path[@]}"
)

export PATH

eval "$(starship init zsh)"

# runs opencode from .dotfiles
opencode() {
  XDG_CONFIG_HOME="$HOME/.dotfiles/.config" command opencode "$@"
}

# source all config files
for file in "$DOTFILES_HOME"/zsh/.zshrc.d/*.zsh; do
	[[ -f "$file" ]] || continue
	# shellcheck disable=SC1090
	source "$file"
done


if command -v brew >/dev/null 2>&1; then
  BREW_PREFIX="$(brew --prefix)"

  fpath=("$BREW_PREFIX/share/zsh-completions" $fpath)
  fpath=("$HOME/.zsh/completions" $fpath)

  mkdir -p ~/.cache/zsh
  autoload -Uz compinit
  compinit -d ~/.cache/zsh/zcompdump-"$ZSH_VERSION"

  source "$BREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
  source "$BREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi

# options
setopt AUTO_PUSHD
setopt PUSHD_IGNORE_DUPS
setopt PUSHD_SILENT

# opencode
export PATH=/Users/klaus224/.opencode/bin:$PATH

# pnpm
export PNPM_HOME="$HOME/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME/bin:"*) ;;
  *) export PATH="$PNPM_HOME/bin:$PATH" ;;
esac
# pnpm end
