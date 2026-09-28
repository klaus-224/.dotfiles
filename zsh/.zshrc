[[ -n "${ZSH_VERSION:-}" && -o interactive ]] || return 0
emulate -LR zsh
export DOTFILES_HOME="${DOTFILES_HOME:-$HOME/.dotfiles}"

typeset -U path PATH

path=(
	"${DOTFILES_HOME:-$HOME/.dotfiles}/bin"
	"$HOME/.local/bin"  
	"${path[@]}"
)
export PATH

if (( $+commands[starship] )); then
	eval "$(starship init zsh)"
fi

eval "$(mise activate zsh)"

[[ -r "$DOTFILES_HOME/zsh/.zshrc.d/vim-mode.zsh" ]] && source "$DOTFILES_HOME/zsh/.zshrc.d/vim-mode.zsh"

for file in "$DOTFILES_HOME"/zsh/.zshrc.d/*.zsh(N); do
	[[ "$file:t" == (vim-mode|keybinds).zsh ]] && continue
	[[ -f "$file" ]] || continue
	source "$file"
done

[[ -d "${ZSH_COMPLETIONS:-}" ]] && fpath=("$ZSH_COMPLETIONS" $fpath)
[[ -d "$HOME/.zsh/completions" ]] && fpath=("$HOME/.zsh/completions" $fpath)

mkdir -p "$HOME/.cache/zsh"
autoload -Uz compinit
compinit -d "$HOME/.cache/zsh/zcompdump-$ZSH_VERSION"

[[ -r "${ZSH_AUTOSUGGESTIONS:-}" ]] && source "$ZSH_AUTOSUGGESTIONS"
[[ -r "${ZSH_SYNTAX_HIGHLIGHTING:-}" ]] && source "$ZSH_SYNTAX_HIGHLIGHTING"

setopt AUTO_PUSHD
setopt PUSHD_IGNORE_DUPS
setopt PUSHD_SILENT
