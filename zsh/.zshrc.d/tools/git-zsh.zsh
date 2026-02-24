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
- send: no
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

  local mode pr_number repo head_sha comments_file start_line end_line sent_csv tmp_comments selected delete_id confirm api_err
  local -a delete_ids
  local delim=$'\x1f'
  local -a sent_ids
  local failed=0

  mode=$1
  shift || true
  if [[ "$mode" != "--review" && "$mode" != "--send" && "$mode" != "--delete" ]]; then
    echo "Usage: gpc --review [PR] | gpc --send [PR] | gpc --delete [PR]"
    return 1
  fi

  pr_number=${1:-$(_ghpr_pick_number)} || return 1
  [[ -z "$pr_number" ]] && return 1
  _ghpr_checkout "$pr_number" || return 1
  repo=$(gh repo view --json nameWithOwner -q '.nameWithOwner') || return 1

  comments_file=$(_ghpr_comments_file "$pr_number") || return 1
  _ghpr_ensure_comments_file "$comments_file" || return 1

  if [[ "$mode" == "--review" ]]; then
    GHPR_NUMBER="$pr_number" "${EDITOR:-nvim}" "$comments_file"
    return $?
  fi

  if [[ "$mode" == "--delete" ]]; then
    selected=$(
      gh api "repos/${repo}/pulls/${pr_number}/comments" --paginate --jq '.[] | [.id, .path, ((.line // 0)|tostring), (.body|gsub("\n";"\\n"))] | @tsv' |
      _fzf_git_fzf -m --ansi --delimiter=$'\t' --with-nth=2,3,4 \
        --border-label "🗑️ Delete submitted comment " --header 'TAB to multi-select, ENTER to confirm' \
        --preview "printf '%s' {4} | sed 's/\\\\\\\\n/\\n/g' | (command -v bat >/dev/null && bat --style=plain --color=always -l md || cat)"
    ) || return 1

    [[ -z "$selected" ]] && return 1
    while IFS=$'\t' read -r delete_id _; do
      [[ -n "$delete_id" ]] && delete_ids+=("$delete_id")
    done <<< "$selected"
    [[ ${#delete_ids[@]} -eq 0 ]] && return 1
    printf "Delete %d submitted PR comment(s)? [y/N]: " "${#delete_ids[@]}"
    read -r confirm || return 1
    [[ "$confirm" != "y" && "$confirm" != "Y" ]] && return 0

    for delete_id in "${delete_ids[@]}"; do
      gh api -X DELETE "repos/${repo}/pulls/comments/${delete_id}" > /dev/null || return 1
      echo "Deleted submitted comment ${delete_id}."
    done
    return 0
  fi

  head_sha=$(gh pr view "$pr_number" --json headRefOid -q '.headRefOid') || return 1

  while IFS="$delim" read -r entry_id file line range body; do
    body=${body//\\n/$'\n'}
    [[ -z "$entry_id" || -z "$file" || -z "$body" ]] && continue
    file=${file#*HEAD:}
    file=${file#*origin/main:}
    file=$(printf '%s' "$file" | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//')
    [[ -z "$file" ]] && { failed=1; continue; }

    if [[ -n "$range" && "$range" == *-* ]]; then
      start_line=${range%-*}
      end_line=${range#*-}
      start_line=$(printf '%s' "$start_line" | tr -d '[:space:]')
      end_line=$(printf '%s' "$end_line" | tr -d '[:space:]')
      api_err=$(
        gh api "repos/${repo}/pulls/${pr_number}/comments" \
        -f body="$body" \
        -f commit_id="$head_sha" \
        -f path="$file" \
        -f side='RIGHT' \
        -f start_side='RIGHT' \
        -F start_line="$start_line" \
        -F line="$end_line" 2>&1 > /dev/null
      )
      if [[ $? -ne 0 ]]; then
        gh api "repos/${repo}/pulls/${pr_number}/comments" \
          -f body="[line-range ${start_line}-${end_line}] ${body}" \
          -f commit_id="$head_sha" \
          -f path="$file" \
          -f subject_type='file' > /dev/null 2>&1 || {
            echo "Failed inline range ${file}:${start_line}-${end_line}: ${api_err}"
            failed=1
            continue
          }
        echo "Added file-level fallback comment for ${file}:${start_line}-${end_line} on PR #${pr_number}."
      else
        echo "Added inline range comment to ${file}:${start_line}-${end_line} on PR #${pr_number}."
      fi
    else
      [[ -z "$line" ]] && { failed=1; continue; }
      line=$(printf '%s' "$line" | tr -d '[:space:]')
      api_err=$(
        gh api "repos/${repo}/pulls/${pr_number}/comments" \
        -f body="$body" \
        -f commit_id="$head_sha" \
        -f path="$file" \
        -f side='RIGHT' \
        -F line="$line" 2>&1 > /dev/null
      )
      if [[ $? -ne 0 ]]; then
        gh api "repos/${repo}/pulls/${pr_number}/comments" \
          -f body="[line ${line}] ${body}" \
          -f commit_id="$head_sha" \
          -f path="$file" \
          -f subject_type='file' > /dev/null 2>&1 || {
            echo "Failed inline ${file}:${line}: ${api_err}"
            failed=1
            continue
          }
        echo "Added file-level fallback comment for ${file}:${line} on PR #${pr_number}."
      else
        echo "Added inline comment to ${file}:${line} on PR #${pr_number}."
      fi
    fi
    sent_ids+=("$entry_id")
  done < <(
    awk -v d="$delim" '
      BEGIN { RS="## Entry[[:space:]]*\n"; ORS="" }
      NR == 1 { next }
      {
        idx++
        n = split($0, lines, /\n/)
        send = ""; file = ""; line = ""; range = ""; comment = ""; in_comment = 0
        for (i = 1; i <= n; i++) {
          l = lines[i]
          if (l ~ /^- send:[[:space:]]*/) {
            send = tolower(l); sub(/^- send:[[:space:]]*/, "", send); in_comment = 0; continue
          }
          if (l ~ /^- file:[[:space:]]*/) {
            file = l; sub(/^- file:[[:space:]]*/, "", file); in_comment = 0; continue
          }
          if (l ~ /^- line:[[:space:]]*/) {
            line = l; sub(/^- line:[[:space:]]*/, "", line); in_comment = 0; continue
          }
          if (l ~ /^- range:[[:space:]]*/) {
            range = l; sub(/^- range:[[:space:]]*/, "", range); in_comment = 0; continue
          }
          if (l ~ /^- comment:[[:space:]]*/) {
            comment = l; sub(/^- comment:[[:space:]]*/, "", comment); in_comment = 1; continue
          }
          if (in_comment && l ~ /^- [a-zA-Z_][-a-zA-Z_]*:[[:space:]]*/) { in_comment = 0 }
          if (in_comment) { comment = comment "\\n" l; continue }
        }
        if ((send == "y" || send == "yes" || send == "true" || send == "1" || send == "x" || send == "[x]") && file != "" && comment != "") {
          printf "%d%s%s%s%s%s%s%s%s\n", idx, d, file, d, line, d, range, d, comment
        }
      }
    ' "$comments_file"
  )

  if [[ ${#sent_ids[@]} -eq 0 ]]; then
    echo "No marked comments were sent. Mark entries with '- send: yes' and run gpc again."
    GHPR_NUMBER="$pr_number" "${EDITOR:-nvim}" "$comments_file"
    return $failed
  fi

  sent_csv=$(IFS=,; echo "${sent_ids[*]}")
  tmp_comments="${comments_file}.tmp.$$"
  awk -v sent="$sent_csv" '
    BEGIN {
      n = split(sent, ids, ",")
      for (i = 1; i <= n; i++) if (ids[i] != "") remove[ids[i]] = 1
      entry = 0; started = 0; keep = 1
    }
    {
      if ($0 ~ /^## Entry[[:space:]]*$/) {
        entry++
        started = 1
        keep = !(entry in remove)
      }
      if (!started) { print; next }
      if (keep) print
    }
  ' "$comments_file" > "$tmp_comments" && mv "$tmp_comments" "$comments_file"
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
  gpc --review [PR]  Open queued comments file for marking/editing.
  gpc --send [PR]    Send only entries marked '- send: yes'.
  gpc --delete [PR]  Pick one submitted PR comment and delete it (with confirm).
  gpd [PR] [FILE] Open changed file in nvim -d vs PR base.
  gps [PR]    	Submit review (approve / request-changes / comment).

Usage:
  gpr           # pick PR interactively
  gpr 123       # use PR 123 directly
EOF
}
