# Interactive ripgrep with fzf
# Usage: rg-fzf [initial query]
# First word triggers ripgrep search, subsequent words filter with fzf
# Press Enter to open file in $EDITOR at the matching line
rg-fzf() {
  local TEMP=$(mktemp -u)
  trap 'rm -f "$TEMP"' EXIT
  
  local INITIAL_QUERY="${*:-}"
  local TRANSFORMER='
    rg_pat={q:1}      # The first word is passed to ripgrep
    fzf_pat={q:2..}   # The rest are passed to fzf

    if ! [[ -r "$TEMP" ]] || [[ $rg_pat != $(cat "$TEMP") ]]; then
      echo "$rg_pat" > "$TEMP"
      printf "reload:sleep 0.1; rg --column --line-number --no-heading --color=always --smart-case %q || true" "$rg_pat"
    fi
    echo "+search:$fzf_pat"
  '
  
  fzf --ansi --disabled --query "$INITIAL_QUERY" \
      --with-shell 'bash -c' \
      --bind "start,change:transform:$TRANSFORMER" \
      --color "hl:-1:underline,hl+:-1:underline:reverse" \
      --delimiter :  | ${EDITOR:-nvim} {1} +{2}
      # --preview 'bat --color=always {1} --highlight-line {2} 2>/dev/null || cat {1}' \
      # --preview-window 'up,60%,border-line,+{2}+3/3,~3' \
      # --bind "enter:become(${EDITOR:-nvim} {1} +{2})"
}
