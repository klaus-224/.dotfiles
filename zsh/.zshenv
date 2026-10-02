export CODE_DIR="$HOME/code"
export EDITOR="nvim"
export VISUAL="nvim"
export TODO_FILE="$CODE_DIR/todo.md"

export RAINFROG_CONFIG="$DOTFILES_HOME/rainfrog"

export STARSHIP_CONFIG="$DOTFILES_HOME/starship/starship.toml"
export GH_DASH_CONFIG="$DOTFILES_HOME/git/gh-dash/config.yml"
export SMOLVM_WORKSPACE="$HOME/code/smolvm/workspace"

export OPENCODE_SESH_DB="$HOME/.local/share/opencode/opencode.db"
export GLOBAL_GITIGNORE="$HOME/.gitignore.global"
export RIPGREP_CONFIG_PATH="$DOTFILES_HOME/ripgrep/.ripgreprc"
export GLAMOUR_STYLE="$DOTFILES_HOME/glow/vague.json"

# non-interactive shells can use mise environment and tools
typeset -U path PATH
path=("$HOME/.local/share/mise/shims" "${path[@]}")
export PATH
