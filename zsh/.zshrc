# --------------------------------------------------
#  entry point for zsh configuration
# --------------------------------------------------
[[ -n "${ZSH_VERSION:-}" ]] || return 0
emulate -LR zsh
export DOTFILES_HOME=""
# source custom env vars
# shellcheck source=/dev/null
source "$HOME/.zshenv"

# add to path
eval "$(starship init zsh)"

# have to source path first
source "$DOTFILES_HOME/zsh/path.zsh"

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

# learnings-store
# source "/Users/rohineshram/code/skyon.pw-agent/.agents/learnings-store/env.sh"
