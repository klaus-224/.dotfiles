function  mans(){
    man -k . \
    | fzf -n1,2 --preview "echo {1} \
    | cut -d' ' -f1 \
    | sed 's#,$##' \
    | sed -E 's#^([^(]+)\(([^)]+)\)$#\2 \1#' \
    | xargs -I% sh -c 'MANPAGER=cat man % 2>/dev/null | col -bx | bat --style=plain --paging=never --color=always'" --bind "enter:execute: \
      (echo {1} \
      | cut -d' ' -f1 \
      | sed 's#,$##' \
      | sed -E 's#^([^(]+)\(([^)]+)\)$#\2 \1#' \
      | xargs -I% man % \
      | less -R)"
}
