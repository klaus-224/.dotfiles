# --------------------------------------------------
#  entry point for zsh configuration
# --------------------------------------------------
[[ -n "${ZSH_VERSION:-}" && -o interactive ]] || return 0
emulate -LR zsh
export DOTFILES_HOME="${DOTFILES_HOME:-$HOME/.dotfiles}"

typeset -U path PATH

path=(
	"${DOTFILES_HOME:-$HOME/.dotfiles}/bin"
	"$HOME/.local/bin"  
	"${path[@]}"
)
# LOCAL_BIN is optional; an unset value must not add /go/bin.
[[ -n "${LOCAL_BIN:-}" ]] && path=("$LOCAL_BIN/go/bin" "${path[@]}")

export PATH

if (( $+commands[starship] )); then
	eval "$(starship init zsh)"
fi

# auto activate mise env
eval "$(mise activate zsh)"

# Choose the keymap before applying personal bindings.
[[ -r "$DOTFILES_HOME/zsh/.zshrc.d/vim-mode.zsh" ]] && source "$DOTFILES_HOME/zsh/.zshrc.d/vim-mode.zsh"
# Source modular config (including optional local.zsh), then bind available widgets.
for file in "$DOTFILES_HOME"/zsh/.zshrc.d/*.zsh(N); do
	[[ "$file:t" == (vim-mode|keybinds).zsh ]] && continue
	[[ -f "$file" ]] || continue
	source "$file"
done
[[ -r "$DOTFILES_HOME/zsh/.zshrc.d/keybinds.zsh" ]] && source "$DOTFILES_HOME/zsh/.zshrc.d/keybinds.zsh"

# Completions
[[ -d "${ZSH_COMPLETIONS:-}" ]] && fpath=("$ZSH_COMPLETIONS" $fpath)
[[ -d "$HOME/.zsh/completions" ]] && fpath=("$HOME/.zsh/completions" $fpath)

mkdir -p "$HOME/.cache/zsh"
autoload -Uz compinit
compinit -d "$HOME/.cache/zsh/zcompdump-$ZSH_VERSION"

# Plugins
[[ -r "${ZSH_AUTOSUGGESTIONS:-}" ]] && source "$ZSH_AUTOSUGGESTIONS"
[[ -r "${ZSH_SYNTAX_HIGHLIGHTING:-}" ]] && source "$ZSH_SYNTAX_HIGHLIGHTING"

# options
setopt AUTO_PUSHD
setopt PUSHD_IGNORE_DUPS
setopt PUSHD_SILENT
