export DOTFILES_HOME="${DOTFILES_HOME:-$HOME/.dotfiles}"
export CODE_DIR="$HOME/code"
export EDITOR="nvim"

export STARSHIP_CONFIG="$DOTFILES_HOME/starship/starship.toml"

export GH_DASH_CONFIG="$DOTFILES_HOME/git/gh-dash/config.yml"
export SMOLVM_WORKSPACE="$HOME/code/smolvm/workspace"

export OPENCODE_SESH_DB="$HOME/.local/share/opencode/opencode.db"

# global .gitignore
export GLOBAL_GITIGNORE="$HOME/.gitignore.global"

# ripgrep config
export RIPGREP_CONFIG_PATH="$DOTFILES_HOME/ripgrep/.ripgreprc"

# glow 
export GLAMOUR_STYLE="$DOTFILES_HOME/glow/vague.json"

# non-interactive shells can use mise environment and tools
typeset -U path PATH
path=("$HOME/.local/share/mise/shims" "${path[@]}")
export PATH

# V2 uses this directory as its global config root, including cli.json.
# Clear the old file override so profiles cannot be merged accidentally.
# unset OPENCODE_CONFIG
# if [[ $USER == "klaus224" ]]; then
#   export OPENCODE_CONFIG_DIR="$DOTFILES_HOME/opencode/personal"
# else
#   export OPENCODE_CONFIG_DIR="$DOTFILES_HOME/opencode/work"
# fi
