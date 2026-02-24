# --------------------------------------------------
# git.zsh
# PR review helpers for gh + Neovim
#
# Function Pneumonics
# [G]ithub [P]R [P]pick = gpp
# [G]ithub [P]R [R]eview = gpr
# [G]ithub [P]R [C]omment = gpc
# [G]ithub [P]R [D]iff open = gpd
# [G]ithub [P]R [S]submit = gps
# [G]ithub [P]R [H]elp = gph
#
# Workflow:
# 1) Pick/enter PR number (all commands accept optional PR number)
# 2) gpr [PR]     -> open PR context markdown in Neovim
# 3) gpc [PR]  -> add one inline comment to a changed file/line
# 4) gpd [PR] [FILE] -> open file in nvim -d against PR base
# 5) gps [PR]   -> submit approve/request-changes/comment review
# Help gph
# --------------------------------------------------

function _ghpr_require() {
  git rev-parse > /dev/null 2>&1 || return 1
  command -v gh > /dev/null 2>&1 || return 1
}

function _ghpr_pick_number() {
  _ghpr_require || return 1

  local selected_pr
  selected_pr=$(
    gh pr list --json number,title --template '{{range .}}{{.number}} {{.title}}{{"\n"}}{{end}}' |
      _fzf_git_fzf --ansi --border-label 'Pull requests ' \
        --preview 'gh pr view {1} --comments'
  ) || return 1

  echo "${selected_pr%% *}"
}

function _ghpr_pick_file() {
  local pr_number=$1
  local repo=$2

  gh api "repos/${repo}/pulls/${pr_number}/files" --paginate --jq '.[].filename' |
    _fzf_git_fzf --border-label "📄 PR #${pr_number} files " \
      --preview "gh pr diff \"$pr_number\" -- {} | sed -n '1,200p'"
}

function _ghpr_checkout() {
  local pr_number=$1
  gh pr checkout "$pr_number" > /dev/null 2>&1 || return 1
}

function _ghpr_comments_file() {
  local pr_number=$1
  local repo_root cache_dir comments_file
  repo_root=$(git rev-parse --show-toplevel) || return 1
  cache_dir="${repo_root}/.git/tmp"
  mkdir -p "$cache_dir" || return 1
  comments_file="${cache_dir}/pr-${pr_number}-comments.md"
  echo "$comments_file"
}

function _ghpr_ensure_comments_file() {
  local comments_file=$1
  [[ -f "$comments_file" && -s "$comments_file" ]] && return 0
  cat > "$comments_file" <<'EOF'
# GH review comments

## Entry
- file: path/to/file.ext
- line: 42
- range: 42-45
- comment:

EOF
}

function _ghpr_open_diff_file() {
  local _pr_number=$1
  local file=$2

  git fetch origin main --quiet > /dev/null 2>&1 || return 1

  "${EDITOR:-nvim}" -d <(git show "origin/main:${file}" 2>/dev/null || echo) "$file"
}

function gpp() {
  _ghpr_pick_number "$@"
}

unalias gpr 2> /dev/null
function gpr() {
  _ghpr_require || return 1

  local pr_number repo repo_root cache_dir tmpfile comments_file
  pr_number=${1:-$(_ghpr_pick_number)} || return 1
  [[ -z "$pr_number" ]] && return 1
  _ghpr_checkout "$pr_number" || return 1

  repo=$(gh repo view --json nameWithOwner -q '.nameWithOwner') || return 1
  repo_root=$(git rev-parse --show-toplevel) || return 1
  cache_dir="${repo_root}/.git/tmp"
  mkdir -p "$cache_dir" || return 1
  tmpfile="${cache_dir}/pr-${pr_number}.md"
  comments_file=$(_ghpr_comments_file "$pr_number") || return 1
  _ghpr_ensure_comments_file "$comments_file" || return 1

  {
    echo "# PR #${pr_number}: $(gh pr view "$pr_number" --json title -q '.title')"
    echo
    echo "## Description"
    gh pr view "$pr_number" --json body -q '.body'
    echo
    echo "## Changed files"
    gh pr diff "$pr_number" --name-only
    echo
    echo "## Diff"
    echo '```diff'
    gh pr diff "$pr_number"
    echo '```'
  } > "$tmpfile"

  GHPR_NUMBER="$pr_number" "${EDITOR:-nvim}" "+lua require('custom.git-pr').setup(${pr_number})" "$tmpfile"
}

function gpc() {
  _ghpr_require || return 1

  local pr_number repo head_sha comments_file selected entry_id file line range body start_line end_line
  pr_number=${1:-$(_ghpr_pick_number)} || return 1
  [[ -z "$pr_number" ]] && return 1
  _ghpr_checkout "$pr_number" || return 1

  repo=$(gh repo view --json nameWithOwner -q '.nameWithOwner') || return 1
  head_sha=$(gh pr view "$pr_number" --json headRefOid -q '.headRefOid') || return 1
  comments_file=$(_ghpr_comments_file "$pr_number") || return 1
  _ghpr_ensure_comments_file "$comments_file" || return 1

  selected=$(
    python3 - "$comments_file" <<'PY' | _fzf_git_fzf --ansi --delimiter='|' --with-nth=2,3,4,5 \
      --border-label "💬 PR queued comments " --header 'Type to filter comments'
import re, sys, pathlib
path = pathlib.Path(sys.argv[1])
text = path.read_text() if path.exists() else ""
parts = [p.strip() for p in re.split(r'(?m)^## Entry\s*$', text) if p.strip()]
idx = 0
for p in parts:
    file = re.search(r'(?m)^- file:\s*(.*)$', p)
    line = re.search(r'(?m)^- line:\s*(.*)$', p)
    rng = re.search(r'(?m)^- range:\s*(.*)$', p)
    cmt = re.search(r'(?m)^- comment:\s*(.*)$', p)
    idx += 1
    fv = (file.group(1).strip() if file else "")
    lv = (line.group(1).strip() if line else "")
    rv = (rng.group(1).strip() if rng else "")
    cv = (cmt.group(1).strip() if cmt else "")
    if fv or lv or rv or cv:
        print(f"{idx}|{fv}|{lv}|{rv}|{cv}")
PY
  ) || return 1

  IFS='|' read -r entry_id file line range body <<< "$selected"
  [[ -z "$entry_id" || -z "$file" || -z "$body" ]] && return 1

  _ghpr_open_diff_file "$pr_number" "$file" || return 1

  if [[ -n "$range" && "$range" == *-* ]]; then
    start_line=${range%-*}
    end_line=${range#*-}
    gh api "repos/${repo}/pulls/${pr_number}/comments" \
      -f body="$body" \
      -f commit_id="$head_sha" \
      -f path="$file" \
      -f side='RIGHT' \
      -f start_side='RIGHT' \
      -F start_line="$start_line" \
      -F line="$end_line" > /dev/null || return 1
    echo "Added inline range comment to ${file}:${start_line}-${end_line} on PR #${pr_number}."
  else
    [[ -z "$line" ]] && return 1
    gh api "repos/${repo}/pulls/${pr_number}/comments" \
      -f body="$body" \
      -f commit_id="$head_sha" \
      -f path="$file" \
      -F line="$line" > /dev/null || return 1
    echo "Added inline comment to ${file}:${line} on PR #${pr_number}."
  fi

  python3 - "$comments_file" "$entry_id" <<'PY'
import re, sys, pathlib
path = pathlib.Path(sys.argv[1])
target = int(sys.argv[2])
text = path.read_text() if path.exists() else ""
prefix, entries = "", []
m = re.search(r'(?m)^## Entry\s*$', text)
if not m:
    sys.exit(0)
prefix = text[:m.start()].rstrip() + "\n\n"
parts = re.split(r'(?m)^## Entry\s*$', text[m.start():])
for p in parts:
    p = p.strip()
    if p:
        entries.append("## Entry\n" + p + "\n\n")
with path.open("w") as f:
    f.write(prefix)
    for i, e in enumerate(entries, 1):
        if i != target:
            f.write(e)
PY
}

function gpd() {
  _ghpr_require || return 1

  local pr_number repo file
  pr_number=${1:-$(_ghpr_pick_number)} || return 1
  [[ -z "$pr_number" ]] && return 1
  _ghpr_checkout "$pr_number" || return 1

  repo=$(gh repo view --json nameWithOwner -q '.nameWithOwner') || return 1
  file=${2:-$(_ghpr_pick_file "$pr_number" "$repo")} || return 1
  [[ -z "$file" ]] && return 1

  _ghpr_open_diff_file "$pr_number" "$file"
}

function gps() {
  _ghpr_require || return 1

  local pr_number action repo_root cache_dir body_file
  local -a body_args
  pr_number=${1:-$(_ghpr_pick_number)} || return 1
  [[ -z "$pr_number" ]] && return 1
  _ghpr_checkout "$pr_number" || return 1

  action=$(
    printf "approve\nrequest-changes\ncomment\n" |
      _fzf_git_fzf --border-label "✅ PR #${pr_number} review action "
  ) || return 1

  repo_root=$(git rev-parse --show-toplevel) || return 1
  cache_dir="${repo_root}/.git/tmp"
  mkdir -p "$cache_dir" || return 1
  body_file="${cache_dir}/pr-${pr_number}-review.md"
  : > "$body_file"
  "${EDITOR:-nvim}" "$body_file"

  body_args=()
  [[ -s "$body_file" ]] && body_args=(--body-file "$body_file")

  case "$action" in
    approve) gh pr review "$pr_number" --approve "${body_args[@]}" ;;
    request-changes) gh pr review "$pr_number" --request-changes "${body_args[@]}" ;;
    comment) gh pr review "$pr_number" --comment "${body_args[@]}" ;;
    *) return 1 ;;
  esac
}

function gph() {
  cat <<'EOF'
PR review helpers:
  gpp [PR?]     Pick and print PR number.
  gpr [PR]      Open PR context markdown in your editor.
  gpc [PR]      Pick queued comment from .git/tmp/pr-<PR>-comments.md and submit inline.
  gpd [PR] [FILE] Open changed file in nvim -d vs PR base.
  gps [PR]    	Submit review (approve / request-changes / comment).

Usage:
  gpr           # pick PR interactively
  gpr 123       # use PR 123 directly
EOF
}
