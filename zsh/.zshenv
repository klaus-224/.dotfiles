export DOTFILES_HOME="$HOME/.dotfiles"
export CODE_DIR="$HOME/code"
export EDITOR="nvim"
export PAGER=delta

export STARSHIP_CONFIG="$DOTFILES_HOME/starship/starship.toml"

export GH_DASH_CONFIG="$DOTFILES_HOME/git/gh-dash/config.yml"
export SMOLVM_WORKSPACE="$HOME/code/smolvm/workspace"

export OPENCODE_CONFIG_DIR="$DOTFILES_HOME/opencode"
export OPENCODE_PLAN_STORE_BIN="$DOTFILES_HOME/bin/plan_store"
export OPENCODE_SESH_DB="$HOME/.local/share/opencode/opencode.db"
export PLAYWRIGHT_DOCS_DIR="$DOTFILES_HOME/opencode/skills/playwright-docs/references/docs-src"

# repo_idx db
export AGENT_REPO_IDX_DB="$HOME/.local/state/opencode-custom-tools/repos.duckdb"

# agent_memory env vars
export AGENT_MEMORY_DB="$HOME/.local/state/opencode-custom-tools/memory.db"

export TODAY_AGENT_CMD="opencode run --agent jira-operator"

# open code
if [[ "$USER" == "klaus224" ]]; then
  export OPENCODE_CONFIG="$DOTFILES_HOME/opencode/opencode.personal.jsonc"
else
  export OPENCODE_CONFIG="$DOTFILES_HOME/opencode/opencode.work.jsonc"
fi

# navi
export NAVI_CONFIG="$DOTFILES_HOME/navi/config.yaml"

# global .gitignore
export GLOBAL_GITIGNORE="$HOME/.gitignore_global"
