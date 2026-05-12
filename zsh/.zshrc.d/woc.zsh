# --------------------------------------------------
# woc.zsh
# Purpose:
#   Create a worktree and open a tmux window with
#   neovim (left, 75%) and opencode (right, 25%).
#
# Usage:
#   woc <branch> [prompt...]
#
# Examples:
#   woc feature-auth
#   woc feature-auth Fix the login bug
#   woc feature/auth "Implement GH #322"
# --------------------------------------------------

woc() {
  if [[ -z "$TMUX" ]]; then
    echo "Error: not in a tmux session" >&2
    return 1
  fi

  local branch="${1:?Usage: woc <branch> [prompt...]}"
  shift
  local prompt="$*"
  local win_name="${branch//\//-}"

  # Create worktree — wt shell function handles cd into the new path
  wt switch --create "$branch" || return 1
  local wt_path="$(pwd)"

  # New tmux window named after the branch, rooted at worktree
  tmux new-window -n "$win_name" -c "$wt_path"

  # Split right pane at 25% width for opencode
  tmux split-window -h -l 25% -c "$wt_path"

  # Right pane (now selected): launch opencode
  if [[ -n "$prompt" ]]; then
    tmux send-keys "opencode run --agent planner $(printf '%q' "$prompt")" Enter
  else
    tmux send-keys "opencode" Enter
  fi

  # Select left pane and launch neovim
  tmux select-pane -L
  tmux send-keys "nvim" Enter
}
