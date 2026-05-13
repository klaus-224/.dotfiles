export DOTFILES_HOME="$HOME/.dotfiles"
export CODE_DIR="$HOME/code"
export EDITOR="nvim"
export PAGER=delta

export STARSHIP_CONFIG="$DOTFILES_HOME/starship/starship.toml"
export GH_DASH_CONFIG="$DOTFILES_HOME/git/gh-dash/config.yml"
export SMOLVM_WORKSPACE="$HOME/code/smolvm/workspace"

export PLAYWRIGHT_DOCS_DIR="$HOME/.dotfiles/opencode/skills/playwright-docs/references/docs-src"

# open code
if [[ "$USER" == "klaus224" ]]; then
  export OPENCODE_CONFIG="${DOTFILES_HOME:-$HOME/.dotfiles}/opencode/opencode.personal.jsonc"
else
  export OPENCODE_CONFIG="${DOTFILES_HOME:-$HOME/.dotfiles}/opencode/opencode.work.jsonc"
fi

export OPENCODE_CONFIG_DIR="$DOTFILES_HOME/opencode"
export OPENCODE_PLAN_STORE_BIN="$DOTFILES_HOME/bin/plan_store"

export TODAY_AGENT_CMD="opencode run --agent jira-operator"
