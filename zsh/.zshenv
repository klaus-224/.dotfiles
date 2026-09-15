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

if [[ $USER == "klaus224" ]]; then
    export OPENCODE_CONFIG="$DOTFILES_HOME/opencode/opencode.personal.jsonc"
  else
    export OPENCODE_CONFIG="$DOTFILES_HOME/opencode/opencode.work.jsonc"
fi
