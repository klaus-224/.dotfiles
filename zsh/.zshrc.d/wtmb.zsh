# wtmb <feature-branch>: merge current branch into <feature-branch>, creating it if absent
function wtmb() {
    local feature=${1:?usage: wtmb <feature-branch>}
    local current
    current=$(git rev-parse --abbrev-ref HEAD) || return 1
    git fetch origin --quiet 2>/dev/null || true
    if ! git show-ref --verify --quiet "refs/heads/${feature}"; then
        echo "Branch '${feature}' not found. Creating from current HEAD..."
        git branch "${feature}" || return 1
    fi
    git checkout "${feature}" || return 1
    git merge "${current}" --no-ff -m "merge ${current} into ${feature}"
}
