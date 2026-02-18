function  mans(){
    local selected name section
    selected="$(
      man -k . 2>/dev/null \
      | awk -F' - ' '{print $1}' \
      | tr ',' '\n' \
      | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//' \
      | awk 'NF' \
      | sort -u \
      | fzf --prompt='man> ' \
          --preview 'entry={}; name=${entry%%(*}; section=${entry#*(}; section=${section%)}; MANPAGER=cat man "$section" "$name" 2>/dev/null | col -bx | bat --style=plain --paging=never --color=always'
    )"

    [[ -z "$selected" ]] && return

    name="${selected%%(*}"
    section="${selected#*(}"
    section="${section%)}"

    nv "+Man ${section} ${name}"
}
