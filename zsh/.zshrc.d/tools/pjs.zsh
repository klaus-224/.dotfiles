# --------------------------------------------------
# mnemonic: [P]ackage [J]son [S]cripts
# Browse scripts in the nearest package.json with fzf,
# then run the selected script. Auto-detects pnpm or
# npm from the lockfile (pnpm-lock.yaml → pnpm,
# package-lock.json → npm).
#
# Usage: pjs
# --------------------------------------------------

function pjs() {
    local dir="$PWD"

    # Walk up to find the nearest package.json
    while [[ "$dir" != "/" ]]; do
        [[ -f "$dir/package.json" ]] && break
        dir=$(dirname "$dir")
    done

    if [[ ! -f "$dir/package.json" ]]; then
        echo "Error: No package.json found"
        return 1
    fi

    local pkg="$dir/package.json"

    # Auto-detect package manager from lockfile
    local pm="npm"
    if [[ -f "$dir/pnpm-lock.yaml" ]]; then
        pm="pnpm"
    fi

    # Extract script names and let user pick one
    local script
    script=$(rg '"scripts"' -A 1000 "$pkg" | \
        sed '1d' | \
        sed '/^\s*}/q' | \
        sed '$ d' | \
        rg '^\s+"(.+)":\s+"(.+)"' -or '$1 → $2' | \
        fzf --height=60% \
            --header="[$pm run] Select a script from $(basename "$dir")/package.json" \
            --preview "echo '$pm run {1}'" \
            --preview-window=up:1 | \
        awk '{print $1}')

    if [[ -n "$script" ]]; then
        echo "Running: $pm run $script"
        (cd "$dir" && $pm run "$script")
    else
        echo "No script selected"
    fi
}
