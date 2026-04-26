export DOTFILES_HOME="${DOTFILES_HOME:-$HOME/.dotfiles}"

# open code
if [[ "$USER" == "klaus224" ]]; then
  export OPENCODE_CONFIG="${DOTFILES_HOME:-$HOME/.dotfiles}/opencode/opencode.personal.jsonc"
else
  export OPENCODE_CONFIG="${DOTFILES_HOME:-$HOME/.dotfiles}/opencode/opencode.work.jsonc"
fi

export OPENCODE_CONFIG_DIR="$DOTFILES_HOME/opencode"
export OPENCODE_PLAN_STORE_BIN="$DOTFILES_HOME/opencode/bin/plan_store.py"
export OPENCODE_PLAN_DB="$HOME/code/skyon-code.worktrees/agents/plans.db"

## General stuff I like
export EDITOR="nvim"

# prompt config
export STARSHIP_CONFIG="$DOTFILES_HOME/starship/starship.toml"

# gh dash
export GH_DASH_CONFIG="$DOTFILES_HOME/git/gh-dash/config.yml"

# delta as pager
export PAGER=delta
