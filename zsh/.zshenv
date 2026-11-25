export EDITOR="nvim"
export VISUAL="nvim"
export CODE_DIR="$HOME/code"
export TODO_FILE="$CODE_DIR/todo.md"
export ZSH_CONFIG="$DOTFILES_HOME/zsh/"
export NVIM_CONFIG="$DOTFILES_HOME/nvim/"
export GHOSTTY_CONFIG="$DOTFILES_HOME/ghostty/"
export OPENCODE_CONFIG="$DOTFILES_HOME/opencode/"
export RAINFROG_CONFIG="$DOTFILES_HOME/rainfrog"
export STARSHIP_CONFIG="$DOTFILES_HOME/starship/starship.toml"
export GH_DASH_CONFIG="$DOTFILES_HOME/git/gh-dash/config.yml"
export GLOBAL_GITIGNORE="$HOME/.gitignore.global"
export RIPGREP_CONFIG_PATH="$DOTFILES_HOME/ripgrep/.ripgreprc"
# read only git processes do not create a lock on the repo
export GIT_OPTIONAL_LOCKS=0

# non-interactive shells can use mise environment and tools
typeset -U path PATH
path=("$HOME/.local/share/mise/shims" "${path[@]}")
export PATH
