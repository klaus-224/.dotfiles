function manf() {
  man -k . \
  | fzf --prompt='man> ' \
        --preview 'man {1} | col -bx | bat -l man -p' \
        --preview-window=right:70% \
  | awk '{print $1}' \
  | xargs man
}
