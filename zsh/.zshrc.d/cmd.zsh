# --------------------------------------------------
# cmd.zsh
# Purpose:
# 	Lists all aliases available in the current shell session and allows
# 	the user to interactively select one using fzf. The selected command
# 	is then printed to the command line for execution.
# --------------------------------------------------

cmd() {
  local selected

  selected=$(
    {
      for name in ${(k)aliases}; do
        printf "%-20s %s\n" "$name" "${aliases[$name]}"
      done
    } | sort -u | fzf
  )


  [[ -z $selected ]] && return

  local cmd_name
  cmd_name=$(echo "$selected" | awk '{print $1}')

  print -z "$cmd_name"
}
