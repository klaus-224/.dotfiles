# --------------------------------------------------
#  entry point for zsh configuration
# --------------------------------------------------
[[ -n "${ZSH_VERSION:-}" ]] || return 0
emulate -LR zsh

# source custom env vars
# shellcheck source=/dev/null
source "$HOME/.zshenv"
source "$HOME/.dotfiles/zsh/path.zsh"

eval "$(starship init zsh)"

# wrapper to run opencode fom .dotfiles
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
