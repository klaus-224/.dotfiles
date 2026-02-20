

function _git_pr_view() {
    local selected_pr pr_number tmpfile

    # get PR number from list of prs
    selected_pr=$(gh pr list --json number,title --template '{{range .}}{{.number}} {{.title}}{{"\n"}}{{end}}' | fzf --ansi --preview 'gh pr view {1} | bat --color=always --style=plain -l md') || return 1

    # pr number is required for gh diff and gh view
    pr_number=${selected_pr%% *}

    tmpfile="/tmp/pr-${pr_number}.md"
    if [[ -f "$tmpfile" ]]; then
        nvim "$tmpfile"
        return 0
    fi

    {
        echo "# $(gh pr view "$pr_number" --json title -q '.title')"
        echo
        echo "## Description"
        gh pr view "$pr_number" --json body -q '.body'
        echo
        echo "## Changed files"
        gh pr view "$pr_number" --json files -q '.files[].path'
    } > "$tmpfile"

    nvim "$tmpfile"
}
