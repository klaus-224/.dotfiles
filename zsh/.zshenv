export DOTFILES_HOME="$HOME/.dotfiles"
export CODE_DIR="$HOME/code"
export EDITOR="nvim"

export STARSHIP_CONFIG="$DOTFILES_HOME/starship/starship.toml"

export GH_DASH_CONFIG="$DOTFILES_HOME/git/gh-dash/config.yml"
export SMOLVM_WORKSPACE="$HOME/code/smolvm/workspace"

export OPENCODE_CONFIG_DIR="$DOTFILES_HOME/opencode"
export OPENCODE_SESH_DB="$HOME/.local/share/opencode/opencode.db"

# open code
if [[ "$USER" == "klaus224" ]]; then
  export OPENCODE_CONFIG="$DOTFILES_HOME/opencode/opencode.personal.jsonc"
  export OMO_PROFILE="personal"
else
  export OPENCODE_CONFIG="$DOTFILES_HOME/opencode/opencode.work.jsonc"
  export OMO_PROFILE="work"
fi

# global .gitignore
export GLOBAL_GITIGNORE="$HOME/.gitignore.global"

# ripgrep config
export RIPGREP_CONFIG_PATH="$DOTFILES_HOME/ripgrep/.ripgreprc"

# glow tui style
export GLAMOUR_STYLE="$DOTFILES_HOME/glow/vague.json"

# gitlab-tui style
export GLAB_TUI_CONFIG="$DOTFILES_HOME/git/glab-tui/config.toml"                         

