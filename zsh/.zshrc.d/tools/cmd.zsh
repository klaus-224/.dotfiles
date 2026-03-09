# --------------------------------------------------
# cmd.zsh
# Purpose:
# 	Lists all aliases, functions, and commands available in the current shell
# 	session and allows the user to interactively select one using fzf. The
# 	selected command is then printed to the command line for execution.
# --------------------------------------------------

cmd() {
  local selected

  selected=$(
    {
      for name in ${(k)aliases}; do
        printf "%-20s %s\n" "$name" "${aliases[$name]}"
      done

      for name in ${(k)functions}; do
        printf "%-20s %s\n" "$name" "[function]"
      done

      for name in ${(k)commands}; do
        printf "%-20s %s\n" "$name" "$(whence -p "$name")"
      done
    } | sort -u | fzf
  )

  [[ -z $selected ]] && return

  local cmd_name
  cmd_name=$(echo "$selected" | awk '{print $1}')

  print -z "$cmd_name"
}
