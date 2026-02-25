# --------------------------------------------------
# env-vars.zsh
# Purpose:
#   Small fzf viewer for environment variables.
# --------------------------------------------------

unalias envv 2>/dev/null

function envv {
    if ! command -v fzf >/dev/null 2>&1; then
        echo "fzf is required. Install with: brew install fzf" >&2
        return 1
    fi

    env | sort | fzf --height=60% --layout=reverse --prompt='env> '
}
